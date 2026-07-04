#pragma once

#include "lvgl.h"
#include "coverloader.h"
#include "backend/apploader/apploader.h"
#include "uuidstr.h"

typedef struct app_t app_t;

typedef enum {
    APPS_FILTER_ALL = 0,
    APPS_FILTER_FAVORITES,
} apps_filter_t;

typedef struct {
    lv_style_t cover;
    lv_style_t btn;
    lv_style_transition_dsc_t tr_pressed;
    lv_style_transition_dsc_t tr_released;
    lv_img_dsc_t fav_indicator_src;
    lv_img_dsc_t defcover_src;
} appitem_styles_t;


typedef struct {
    lv_fragment_t base;
    app_t *global;
    uuidstr_t uuid;

    int def_app;
    bool def_app_launched;

    bool show_hidden_apps;

    apploader_t *apploader;
    coverloader_t *coverloader;
    apploader_cb_t apploader_cb;

    apploader_list_t *apploader_apps;
    const char *apploader_error;

    lv_obj_t *applist, *appload, *apperror;
    lv_obj_t *errortitle, *errorhint, *errordetail;
    lv_obj_t *actions;

    lv_obj_t *hero_bg, *hero_dim, *hero_title, *filter_bar;

    lv_obj_t *quit_progress;

    appitem_styles_t appitem_style;
    apps_filter_t filter;
    int *filter_indices;
    int filter_count;
    int col_count;
    lv_coord_t col_width, col_height;
    lv_coord_t rail_height;
    int focus_backup;
} apps_fragment_t;

typedef struct {
    int app_id;
    apps_fragment_t *controller;
    const appitem_styles_t *styles;
    lv_obj_t *play_indicator;
    lv_obj_t *title;
} appitem_viewholder_t;

typedef struct {
    app_t *global;
    uuidstr_t host;
    int def_app;
} apps_fragment_arg_t;

extern const lv_fragment_class_t apps_controller_class;

/** Update hero background and title when a game tile receives focus. */
void apps_on_item_focused(apps_fragment_t *controller, int app_id);

/** Move keypad/gamepad focus to the filter tabs row. */
void apps_focus_filter_bar(apps_fragment_t *controller);

/** Move focus into the bottom game rail. */
void apps_focus_rail(apps_fragment_t *controller);