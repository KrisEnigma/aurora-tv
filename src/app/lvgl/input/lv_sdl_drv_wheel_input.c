#include "lvgl/lv_sdl_drv_input.h"

#include <SDL.h>

#include "app.h"
#include "stream/session.h"
#include "stream/session_events.h"
#include "ui/root.h"
#include "ui/ui_input.h"
#include "lv_gridview.h"

static void sdl_input_read(lv_indev_drv_t *drv, lv_indev_data_t *data);

static bool wheel_handle_gridview(app_ui_input_t *input, const SDL_MouseWheelEvent *wheel) {
    if (wheel->y == 0) {
        return false;
    }
    lv_group_t *group = app_input_get_group(input);
    if (group == NULL) {
        return false;
    }
    lv_obj_t *focused = lv_group_get_focused(group);
    if (focused == NULL || !lv_obj_check_type(focused, &lv_gridview_class)) {
        return false;
    }
    /* Wheel down (y > 0) advances one page; wheel up goes back one page. */
    lv_gridview_page(focused, wheel->y > 0);
    return true;
}

int lv_sdl_init_wheel(lv_indev_drv_t *drv, app_ui_input_t *input) {
    lv_indev_drv_init(drv);
    drv->user_data = input;
    drv->type = LV_INDEV_TYPE_ENCODER;
    drv->read_cb = sdl_input_read;

    return 0;
}

static void sdl_input_read(lv_indev_drv_t *drv, lv_indev_data_t *data) {
    app_ui_input_t *input = drv->user_data;
    SDL_Event e;
    data->state = LV_INDEV_STATE_RELEASED;
    data->enc_diff = 0;
    if (SDL_PeepEvents(&e, 1, SDL_GETEVENT, SDL_MOUSEWHEEL, SDL_MOUSEWHEEL)) {
        app_t *app = input->ui->app;
        if (app->session != NULL && !ui_should_block_input()) {
            session_handle_input_event(app->session, &e);
        } else if (wheel_handle_gridview(input, &e.wheel)) {
            /* Page the game grid; do not move group focus or scroll parents. */
        } else if (e.wheel.y != 0) {
            /* Encoder scroll only: never set PRESSED — that triggers LVGL "encoder button" clicks. */
            data->enc_diff = (e.wheel.y > 0) ? -1 : 1;
        }
    }
    data->continue_reading = false;
}
