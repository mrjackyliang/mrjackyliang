/**
 * WooCommerce - Display quantity increment.
 *
 * @since 1.0.0
 */
function display_quantity_increment() {
   echo '<button type="button" class="quantity-button quantity-increment">+</button>';
}

/**
 * WooCommerce - Display quantity decrement.
 *
 * @since 1.0.0
 */
function display_quantity_decrement() {
   echo '<button type="button" class="quantity-button quantity-decrement">-</button>';
}

/**
 * WooCommerce - Quantity updater.
 *
 * @since 1.0.0
 */
function quantity_updater() {
   if ( ! is_product() && ! is_cart() ) {
	   return;
   }

   wc_enqueue_js( "$(document).on(\"click\",\"button.quantity-increment, button.quantity-decrement\",(function(){let t=$(this).parent(\".quantity\").find(\".qty\");let e=parseFloat(t.val())||0;let a=parseFloat(t.attr(\"max\"));let n=parseFloat(t.attr(\"min\"));let l=parseFloat(t.attr(\"step\"));if($(this).is(\".quantity-increment\")){if(a&&a<=e){t.val(a).change()}else{t.val(e+l).change()}}else{if(n&&n>=e){t.val(n).change()}else if(e>1){t.val(e-l).change()}}}));" );
}

add_action( 'woocommerce_before_quantity_input_field', 'display_quantity_decrement' );
add_action( 'woocommerce_after_quantity_input_field', 'display_quantity_increment' );
add_action( 'wp_footer', 'quantity_updater' );
