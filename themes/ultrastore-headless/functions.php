<?php
// Minimal headless theme: no front-end rendering.
// Ensure WooCommerce REST API support if WooCommerce is active.
add_action('after_setup_theme', function () {
    add_theme_support('title-tag');
});

add_action('init', function () {
    // Keep permalinks endpoints working without front templates.
});
