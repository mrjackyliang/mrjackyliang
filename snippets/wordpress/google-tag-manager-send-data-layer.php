/**
 * Google Tag Manager - Send Data Layer (head).
 *
 * @since 1.0.0
 */
function google_tag_manager_send_data_layer_head() {
	$intercom_secret = 'YOUR_INTERCOM_SECRET_HERE';
	
	// WordPress data.
	$current_user = wp_get_current_user();

	// Variables to send.
	$member_id = '';
	$order_id = '';
	$amount = '';
	$user_email = '';
	$display_name = '';
	$avatar_url = '';
	$intercom_user_hash = '';

	// If member_id parameter is set.
	if ( isset( $_GET[ 'member_id' ] ) ) {
		$member_id = htmlspecialchars( $_GET[ 'member_id' ] );
	}

	// If order_id parameter is set.
	if ( isset( $_GET[ 'order_id' ] ) ) {
		$order_id = htmlspecialchars( $_GET[ 'order_id' ] );
	}

	// If amount parameter is set.
	if ( isset( $_GET[ 'amount' ] ) ) {
		$amount = htmlspecialchars( $_GET[ 'amount' ] );
	}

	// If user is logged in.
	if ( $current_user->ID > 0 ) {
		$user_email = $current_user->user_email;
		$display_name = $current_user->display_name;
		$avatar_url = get_avatar_url( $current_user, [
			'size' => 256,
			'default' => 'mystery',
		] );

		// For Intercom.
		$intercom_user_hash = hash_hmac( 'sha256', $user_email, $intercom_secret );
	}

	?>

	<script type="text/javascript">
		var memberId = '<?php echo $member_id; ?>';
		var orderId = '<?php echo $order_id; ?>';
		var amount = '<?php echo $amount; ?>';
		var userEmail = '<?php echo $user_email; ?>';
		var displayName = '<?php echo $display_name; ?>';
		var avatarUrl = '<?php echo $avatar_url; ?>';
		var intercomUserHash = '<?php echo $intercom_user_hash; ?>';

		// If a conversion is detected.
		if (memberId && orderId && amount) {
			dataLayer.push({
				event: 'conversion',
				conversionMemberId: memberId,
				conversionOrderId: orderId,
				conversionOrderAmount: amount,
			});
		}

		// If a signup is detected.
		if (memberId && !orderId && !amount) {
			dataLayer.push({
				event: 'signup',
				signupMemberId: memberId,
			});
		}

		// If user is logged in.
		if (userEmail && displayName && avatarUrl) {
			dataLayer.push({
				userEmail: userEmail,
				userDisplayName: displayName,
				userAvatarUrl: avatarUrl,
			});
		}

		// If intercom user hash exists.
		if (intercomUserHash) {
			dataLayer.push({
				intercomUserHash: intercomUserHash,
			});
		}
	</script>

	<?php

}

add_action( 'wp_head', 'google_tag_manager_send_data_layer_head' );
