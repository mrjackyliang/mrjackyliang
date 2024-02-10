/**
 * Delay video playing (head).
 *
 * @since 1.0.0
 */
function delay_video_playing_head() {

	?>

	<script type="text/javascript">
		jQuery(function ($) {
			const videosLength = $(".delay-video-playing video").length;

			for (var i = 0; i < videosLength; i++) {
				const videoId = i;

				setTimeout(function () {
					const video = $(".delay-video-playing video").get(videoId);

					if (video.paused) {
						video.play();
					}
				}, 10000);
			}
		});
	</script>

	<?php

}

add_action( 'wp_head', 'delay_video_playing_head' );
