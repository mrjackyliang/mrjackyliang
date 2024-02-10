/**
 * WooCommerce - Checkout "Legal Docs" Embed.
 *
 * @since 1.0.0
 */
function add_legal_docs_embed() {
	$title       = '<div class="legal-docs-title">Legal Docs</div>';
	$embed_begin = '<div class="legal-docs-embed">';
	$embed_end   = '</div>';

	$embed_terms = [];

	$embed_terms[] = '<div><h2>Terms and Conditions</h2>XXX</div>';
	$embed_terms[] = '<div><h2>Privacy Policy</h2>XXX</div>';
	$embed_terms[] = '<div><h2>Disclaimer</h2>XXX</div>';
	$embed_terms[] = '<div><h2>Return Policy</h2>XXX</div>';

	echo do_shortcode( $title . $embed_begin . implode( $embed_terms ) . $embed_end );
}

/**
 * WooCommerce - Checkout "Legal Docs" Checkbox.
 *
 * @since 1.0.0
 */
function add_legal_docs_checkbox() {
	woocommerce_form_field( 'legal_docs', array(
		'type'        => 'checkbox',
		'class'       => array( 'legal-docs-checkbox' ),
		'label_class' => array( 'woocommerce-form__label woocommerce-form__label-for-checkbox checkbox' ),
		'input_class' => array( 'woocommerce-form__input woocommerce-form__input-checkbox input-checkbox' ),
		'required'    => true,
		'label'       => '<span class="woocommerce-terms-and-conditions-checkbox-text">I hereby acknoledge that I have read and understood the Terms and Conditions, Privacy Policy, Disclaimer, and Return Policy</span>',
	) );
}


/**
 * WooCommerce - Checkout "Legal Docs" Checkbox Error.
 *
 * @since 1.0.0
 */
function add_legal_docs_checkbox_error() {
	if ( ! (int) isset( $_POST[ 'legal_docs' ] ) ) {
		wc_add_notice( __( 'Please read and accept the legal agreements to proceed with your order.' ), 'error' );
	}
}

add_action( 'woocommerce_review_order_before_submit', 'add_legal_docs_embed' );
add_action( 'woocommerce_review_order_before_submit', 'add_legal_docs_checkbox' );
add_action( 'woocommerce_checkout_process', 'add_legal_docs_checkbox_error' );
