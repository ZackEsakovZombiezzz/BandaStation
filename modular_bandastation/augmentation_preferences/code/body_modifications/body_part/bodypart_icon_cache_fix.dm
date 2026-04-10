/**
 * Augmentation Preferences — icon cache key fix.
 *
 * The base generate_icon_key() proc does not include icon_static in the cache
 * key when should_draw_greyscale is FALSE.  All robotic/prosthetic bodyparts
 * (which use different icon_static paths per manufacturer) therefore share the
 * same key, causing the static limb_icon_cache to return the FIRST manufacturer's
 * sprite for every subsequent manufacturer switch.
 *
 * Override: append icon_static to the key whenever the bodypart is rendered
 * using icon_static (i.e. should_draw_greyscale == FALSE), so each manufacturer
 * produces a unique cache entry.
 */
/obj/item/bodypart/generate_icon_key()
	. = ..()
	if(!should_draw_greyscale && icon_static)
		. += "[icon_static]"
