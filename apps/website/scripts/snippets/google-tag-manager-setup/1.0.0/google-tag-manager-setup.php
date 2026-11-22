/**
 * Google Tag Manager (head).
 *
 * @since 1.0.0
 */
function google_tag_manager_head() {
	$gtag = '';

	if ( ! is_string( $gtag ) || empty( $gtag ) ) {
		return;
	}

	?>

	<script type="text/javascript">
        (function(w, d, s, l, i) {
            w[l] = w[l] || [];
            w[l].push({
                'gtm.start': new Date().getTime(),
                event: 'gtm.js'
            });
            var f = d.getElementsByTagName(s)[0],
                j = d.createElement(s),
                dl = l != 'dataLayer' ? '&l=' + l : '';
            j.async = true;
            j.src = 'https://www.googletagmanager.com/gtm.js?id=' + i + dl;
            f.parentNode.insertBefore(j, f);
        })(window, document, 'script', 'dataLayer', '<?php echo $gtag; ?>');
	</script>

	<?php

}

/**
 * Google Tag Manager (body open).
 *
 * @since 1.0.0
 */
function google_tag_manager_body_open() {
	$gtag = '';

	if ( ! is_string( $gtag ) || empty( $gtag ) ) {
		return;
	}

	?>

	<noscript>
		<iframe src="https://www.googletagmanager.com/ns.html?id=<?php echo $gtag; ?>" height="0" width="0" style="display:none;visibility:hidden"></iframe>
	</noscript>

	<?php

}

add_action( 'wp_head', 'google_tag_manager_head' );
add_action( 'wp_body_open', 'google_tag_manager_body_open' );
