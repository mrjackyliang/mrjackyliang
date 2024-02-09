/**
 * WooCommerce - Pagination Arrows.
 *
 * @since 1.0.0
 */
function woocommerce_pagination_arrows( $args ) {
	$args['prev_text'] = '<';
	$args['next_text'] = '>';

	return $args;
}

add_filter( 'woocommerce_pagination_args', 'woocommerce_pagination_arrows' );
