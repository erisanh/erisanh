-- ==============================================================================
-- Compositor Settings
-- ==============================================================================
--
-- All non-visual compositor config blocks: input, cursor, general, layouts,
-- gestures, misc, xwayland, and the binds-behavior section.

hl.config({

	-- -------------------------------------------------------------------------
	-- Cursor
	-- -------------------------------------------------------------------------
	cursor = {
		no_hardware_cursors = 0, -- 0 = use hw cursors if possible
		inactive_timeout = 10,
	},

	-- -------------------------------------------------------------------------
	-- Input
	-- -------------------------------------------------------------------------
	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		-- kb_options = "caps:swapescape",
		kb_rules = "",

		float_switch_override_focus = 0,
		follow_mouse = 2,
		repeat_rate = 25,
		repeat_delay = 200,
		sensitivity = 0.4, -- -1.0 to 1.0, 0 means no modification

		touchpad = {
			natural_scroll = true,
			scroll_factor = 0.4,
			drag_lock = 0,
			tap_and_drag = true,
			clickfinger_behavior = true,
			disable_while_typing = true,
		},
	},

	-- -------------------------------------------------------------------------
	-- General
	-- -------------------------------------------------------------------------
	general = {
		allow_tearing = true,
		gaps_in = 4,
		gaps_out = 10,
		border_size = 2,
		col = {
			-- Static multi-color gradient border (plan.theme.md §1): alive, ZERO
			-- animation cost. The "playful" anim preset adds a borderangle loop to
			-- rotate it (opt-in only — keeps default battery-friendly, §10).
			-- primary #95CDF7 -> tertiary #CEC0E8 -> secondary #B7C9D9, 45deg.
			active_border = "rgba(95cdf7ff) rgba(cec0e8ff) rgba(b7c9d9ff) 45deg",
			-- Subtle hairline tone-matched to the #0f120e base (not a 2nd hue).
			inactive_border = "rgba(2b302aff)",
		},
		layout = "scrolling",

		snap = {
			enabled = true,
			window_gap = 10,
			monitor_gap = 10,
		},
	},

	-- -------------------------------------------------------------------------
	-- Scrolling layout
	-- -------------------------------------------------------------------------
	scrolling = {
		fullscreen_on_one_column = true,
		-- column_width = 0.45,
		focus_fit_method = 1,
		explicit_column_widths = "0.333, 0.5, 0.667",
	},

	-- -------------------------------------------------------------------------
	-- Misc
	-- -------------------------------------------------------------------------
	misc = {
		-- Flat dark base behind windows / where no wallpaper paints (plan §9.2 / §4).
		-- Single background hue #0f120e for the whole desktop.
		background_color = "rgb(0f120e)",
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		mouse_move_enables_dpms = true,
		enable_swallow = false,
		swallow_regex = "^(org\\.wezfurlong\\.wezterm)$",
		vrr = 1,
	},

	-- -------------------------------------------------------------------------
	-- XWayland
	-- Avoid blurry XWayland apps by forcing 1:1 scaling.
	-- -------------------------------------------------------------------------
	xwayland = {
		force_zero_scaling = true,
	},

	-- -------------------------------------------------------------------------
	-- Gestures (config values only; the gesture itself is in binds.lua)
	-- -------------------------------------------------------------------------
	gestures = {
		workspace_swipe_cancel_ratio = 0.2,
		workspace_swipe_min_speed_to_force = 5,
		workspace_swipe_direction_lock = true,
	},

	-- -------------------------------------------------------------------------
	-- Dwindle and Master
	-- Kept for layout-switch compatibility even though active layout is
	-- scrolling.
	-- -------------------------------------------------------------------------
	dwindle = {
		preserve_split = true,
		smart_split = false,
		smart_resizing = false,
	},

	master = {
		new_status = "master",
	},

	-- -------------------------------------------------------------------------
	-- Binds behavior
	-- -------------------------------------------------------------------------
	binds = {
		allow_workspace_cycles = true,
		movefocus_cycles_fullscreen = true,
	},
})
