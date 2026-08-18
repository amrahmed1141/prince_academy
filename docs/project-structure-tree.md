# Prince Academy — Project File Structure

> Generated: 2026-07-28 10:12:56
> Root: `d:\flutter_projects\prince_academy`
> Total entries: 1851

## Excluded from this tree

Build artifacts and dependencies are omitted for readability:

- `.git/`, `build/`, `.dart_tool/`, `node_modules/`
- `.gradle/`, `Pods/`, `.idea/`, `.kilo/`
- `.github/modernize/`, `.github/java-upgrade/`, `.mvn/`

## Directory tree

```text
prince_academy/
|-- .cursor
|   |-- agents
|   |   `-- README.md
|   |-- rules
|   |   |-- core
|   |   |   |-- 00-platform-contract.mdc
|   |   |   |-- 01-change-discipline.mdc
|   |   |   `-- 02-definition-of-done.mdc
|   |   |-- data
|   |   |   |-- auth-boundary.mdc
|   |   |   |-- caching-sync.mdc
|   |   |   |-- repository-boundary.mdc
|   |   |   |-- secrets-config.mdc
|   |   |   `-- supabase-sql.mdc
|   |   |-- flutter
|   |   |   |-- dependency-injection.mdc
|   |   |   |-- error-observability.mdc
|   |   |   |-- feature-layout.mdc
|   |   |   |-- models-mapping.mdc
|   |   |   |-- naming-imports.mdc
|   |   |   |-- navigation-shell.mdc
|   |   |   |-- state-management.mdc
|   |   |   `-- ui-theme-accessibility.mdc
|   |   |-- product
|   |   |   |-- academy-domain.mdc
|   |   |   |-- admin-operations.mdc
|   |   |   |-- deprecations.mdc
|   |   |   `-- fcm-notifications.mdc
|   |   `-- quality
|   |       |-- documentation.mdc
|   |       |-- generated-files.mdc
|   |       |-- performance.mdc
|   |       |-- review.mdc
|   |       `-- testing.mdc
|   `-- skills
|       `-- README.md
|-- .github
|-- .vscode
|   |-- c_cpp_properties.json
|   |-- launch.json
|   `-- settings.json
|-- agents
|   |-- architect.md
|   |-- database.md
|   |-- documentation.md
|   |-- flutter-developer.md
|   |-- INDEX.md
|   |-- orchestrator.md
|   |-- performance.md
|   |-- qa.md
|   |-- release.md
|   |-- reviewer.md
|   `-- security.md
|-- ai
|   |-- context
|   |   |-- _template.md
|   |   |-- admin-dashboard.md
|   |   |-- architecture.md
|   |   |-- attendance.md
|   |   |-- authentication.md
|   |   |-- booking.md
|   |   |-- INDEX.md
|   |   |-- notifications.md
|   |   |-- payments.md
|   |   |-- subscriptions.md
|   |   `-- supabase.md
|   |-- memory
|   |   |-- architecture.md
|   |   |-- business-rules.md
|   |   |-- coding-decisions.md
|   |   |-- INDEX.md
|   |   |-- known-pitfalls.md
|   |   |-- lessons-learned.md
|   |   `-- project-history.md
|   |-- prompts
|   |   |-- _template.md
|   |   |-- architecture-review.md
|   |   |-- bug-fix.md
|   |   |-- code-review.md
|   |   |-- documentation.md
|   |   |-- feature-planning.md
|   |   |-- INDEX.md
|   |   |-- performance-review.md
|   |   |-- release.md
|   |   `-- sql.md
|   |-- standards
|   |   |-- bloc.md
|   |   |-- flutter.md
|   |   |-- INDEX.md
|   |   |-- models.md
|   |   |-- repository.md
|   |   |-- supabase.md
|   |   |-- testing.md
|   |   `-- ui.md
|   |-- templates
|   |   |-- _base.md
|   |   |-- bug-fix.md
|   |   |-- documentation.md
|   |   |-- feature.md
|   |   |-- README.md
|   |   |-- release.md
|   |   |-- review.md
|   |   `-- sql-change.md
|   |-- workflows
|   |   |-- _template.md
|   |   |-- bug-fix.md
|   |   |-- database-change.md
|   |   |-- feature-development.md
|   |   |-- hot-fix.md
|   |   |-- INDEX.md
|   |   |-- performance-optimisation.md
|   |   |-- refactoring.md
|   |   `-- release.md
|   `-- README.md
|-- android
|   |-- app
|   |   |-- src
|   |   |   |-- debug
|   |   |   |   `-- AndroidManifest.xml
|   |   |   |-- main
|   |   |   |   |-- java
|   |   |   |   |   `-- io
|   |   |   |   |       `-- flutter
|   |   |   |   |           `-- plugins
|   |   |   |   |               `-- GeneratedPluginRegistrant.java
|   |   |   |   |-- kotlin
|   |   |   |   |   `-- com
|   |   |   |   |       `-- example
|   |   |   |   |           `-- prince_academy
|   |   |   |   |               `-- MainActivity.kt
|   |   |   |   |-- res
|   |   |   |   |   |-- drawable
|   |   |   |   |   |   `-- launch_background.xml
|   |   |   |   |   |-- drawable-v21
|   |   |   |   |   |   `-- launch_background.xml
|   |   |   |   |   |-- mipmap-anydpi-v26
|   |   |   |   |   |   `-- ic_launcher.xml
|   |   |   |   |   |-- mipmap-hdpi
|   |   |   |   |   |   |-- ic_launcher.png
|   |   |   |   |   |   |-- ic_launcher_foreground.png
|   |   |   |   |   |   `-- launcher_icon.png
|   |   |   |   |   |-- mipmap-mdpi
|   |   |   |   |   |   |-- ic_launcher.png
|   |   |   |   |   |   |-- ic_launcher_foreground.png
|   |   |   |   |   |   `-- launcher_icon.png
|   |   |   |   |   |-- mipmap-xhdpi
|   |   |   |   |   |   |-- ic_launcher.png
|   |   |   |   |   |   |-- ic_launcher_foreground.png
|   |   |   |   |   |   `-- launcher_icon.png
|   |   |   |   |   |-- mipmap-xxhdpi
|   |   |   |   |   |   |-- ic_launcher.png
|   |   |   |   |   |   |-- ic_launcher_foreground.png
|   |   |   |   |   |   `-- launcher_icon.png
|   |   |   |   |   |-- mipmap-xxxhdpi
|   |   |   |   |   |   |-- ic_launcher.png
|   |   |   |   |   |   |-- ic_launcher_foreground.png
|   |   |   |   |   |   `-- launcher_icon.png
|   |   |   |   |   |-- values
|   |   |   |   |   |   |-- colors.xml
|   |   |   |   |   |   `-- styles.xml
|   |   |   |   |   `-- values-night
|   |   |   |   |       `-- styles.xml
|   |   |   |   |-- AndroidManifest.xml
|   |   |   |   `-- ic_launcher-playstore.png
|   |   |   `-- profile
|   |   |       `-- AndroidManifest.xml
|   |   |-- build.gradle
|   |   `-- google-services.json
|   |-- gradle
|   |   `-- wrapper
|   |       |-- gradle-wrapper.jar
|   |       `-- gradle-wrapper.properties
|   |-- .gitignore
|   |-- build.gradle
|   |-- gradle.properties
|   |-- gradlew
|   |-- gradlew.bat
|   |-- local.properties
|   |-- prince_academy_android.iml
|   `-- settings.gradle
|-- assets
|   |-- animations
|   |   |-- .gitkeep
|   |   `-- pull_refresh.gif
|   |-- coaches
|   |   |-- fayo.jpeg
|   |   |-- shently.jpeg
|   |   `-- zombie.jpeg
|   |-- fonts
|   |   |-- Poppins-Black.ttf
|   |   |-- Poppins-BlackItalic.ttf
|   |   |-- Poppins-Bold.ttf
|   |   |-- Poppins-BoldItalic.ttf
|   |   |-- Poppins-ExtraBold.ttf
|   |   |-- Poppins-ExtraBoldItalic.ttf
|   |   |-- Poppins-ExtraLight.ttf
|   |   |-- Poppins-ExtraLightItalic.ttf
|   |   |-- Poppins-Italic.ttf
|   |   |-- Poppins-Light.ttf
|   |   |-- Poppins-LightItalic.ttf
|   |   |-- Poppins-Medium.ttf
|   |   |-- Poppins-MediumItalic.ttf
|   |   |-- Poppins-Regular.ttf
|   |   |-- Poppins-SemiBold.ttf
|   |   |-- Poppins-SemiBoldItalic.ttf
|   |   |-- Poppins-Thin.ttf
|   |   `-- Poppins-ThinItalic.ttf
|   |-- icons
|   |   |-- app_logo.png
|   |   |-- facebook.png
|   |   |-- google.png
|   |   `-- logo.png
|   `-- images
|       |-- bjj.jpg
|       |-- box.jpg
|       |-- kickbox.jpg
|       `-- mma.jpg
|-- docs
|   |-- _templates
|   |   |-- adr.md
|   |   |-- doc-page.md
|   |   `-- README.md
|   |-- architecture
|   |   `-- README.md
|   |-- database
|   |   `-- README.md
|   |-- decisions
|   |   `-- README.md
|   |-- generated
|   |   `-- README.md
|   |-- operations
|   |   `-- README.md
|   |-- product
|   |   `-- README.md
|   |-- security
|   |   `-- README.md
|   |-- tasks
|   |   `-- task_002_admin_dashboard_navigation.md
|   |-- architecture-overview.md
|   |-- auth-and-roles.md
|   |-- caching-and-sync.md
|   |-- deprecation-list.md
|   |-- environment-setup.md
|   |-- feature-playbook.md
|   |-- README.md
|   |-- security-notes.md
|   |-- supabase-schema-and-rpc.md
|   |-- testing-guide.md
|   `-- ui-theme-guide.md
|-- examples
|   |-- cubit
|   |   |-- excerpt.md
|   |   `-- README.md
|   |-- navigation
|   |   `-- README.md
|   |-- repository
|   |   |-- excerpt.md
|   |   `-- README.md
|   |-- rpc
|   |   |-- excerpt.md
|   |   `-- README.md
|   |-- screen
|   |   |-- excerpt.md
|   |   `-- README.md
|   |-- supabase_repository
|   |   |-- excerpt.md
|   |   `-- README.md
|   |-- tests
|   |   |-- excerpt.md
|   |   `-- README.md
|   |-- widget
|   |   |-- excerpt.md
|   |   `-- README.md
|   `-- README.md
|-- ios
|   |-- Flutter
|   |   |-- AppFrameworkInfo.plist
|   |   |-- Debug.xcconfig
|   |   |-- flutter_export_environment.sh
|   |   |-- Generated.xcconfig
|   |   `-- Release.xcconfig
|   |-- Runner
|   |   |-- Assets.xcassets
|   |   |   |-- AppIcon.appiconset
|   |   |   |   |-- Contents.json
|   |   |   |   |-- Icon-App-1024x1024@1x.png
|   |   |   |   |-- Icon-App-20x20@1x.png
|   |   |   |   |-- Icon-App-20x20@2x.png
|   |   |   |   |-- Icon-App-20x20@3x.png
|   |   |   |   |-- Icon-App-29x29@1x.png
|   |   |   |   |-- Icon-App-29x29@2x.png
|   |   |   |   |-- Icon-App-29x29@3x.png
|   |   |   |   |-- Icon-App-38x38@2x.png
|   |   |   |   |-- Icon-App-38x38@3x.png
|   |   |   |   |-- Icon-App-40x40@1x.png
|   |   |   |   |-- Icon-App-40x40@2x.png
|   |   |   |   |-- Icon-App-40x40@3x.png
|   |   |   |   |-- Icon-App-50x50@1x.png
|   |   |   |   |-- Icon-App-50x50@2x.png
|   |   |   |   |-- Icon-App-57x57@1x.png
|   |   |   |   |-- Icon-App-57x57@2x.png
|   |   |   |   |-- Icon-App-60x60@2x.png
|   |   |   |   |-- Icon-App-60x60@3x.png
|   |   |   |   |-- Icon-App-64x64@2x.png
|   |   |   |   |-- Icon-App-64x64@3x.png
|   |   |   |   |-- Icon-App-68x68@2x.png
|   |   |   |   |-- Icon-App-72x72@1x.png
|   |   |   |   |-- Icon-App-72x72@2x.png
|   |   |   |   |-- Icon-App-76x76@1x.png
|   |   |   |   |-- Icon-App-76x76@2x.png
|   |   |   |   `-- Icon-App-83.5x83.5@2x.png
|   |   |   `-- LaunchImage.imageset
|   |   |       |-- Contents.json
|   |   |       |-- LaunchImage.png
|   |   |       |-- LaunchImage@2x.png
|   |   |       |-- LaunchImage@3x.png
|   |   |       `-- README.md
|   |   |-- Base.lproj
|   |   |   |-- LaunchScreen.storyboard
|   |   |   `-- Main.storyboard
|   |   |-- AppDelegate.swift
|   |   |-- GeneratedPluginRegistrant.h
|   |   |-- GeneratedPluginRegistrant.m
|   |   |-- GoogleService-Info.plist
|   |   |-- Info.plist
|   |   |-- Runner.entitlements
|   |   `-- Runner-Bridging-Header.h
|   |-- Runner.xcodeproj
|   |   |-- project.xcworkspace
|   |   |   |-- xcshareddata
|   |   |   |   |-- IDEWorkspaceChecks.plist
|   |   |   |   `-- WorkspaceSettings.xcsettings
|   |   |   `-- contents.xcworkspacedata
|   |   |-- xcshareddata
|   |   |   `-- xcschemes
|   |   |       `-- Runner.xcscheme
|   |   `-- project.pbxproj
|   |-- Runner.xcworkspace
|   |   |-- xcshareddata
|   |   |   |-- IDEWorkspaceChecks.plist
|   |   |   `-- WorkspaceSettings.xcsettings
|   |   `-- contents.xcworkspacedata
|   |-- RunnerTests
|   |   `-- RunnerTests.swift
|   |-- .gitignore
|   |-- Podfile
|   `-- Podfile.lock
|-- lib
|   |-- app
|   |   |-- bottom_navigation
|   |   |   |-- models
|   |   |   |   `-- bottom_nav_item_model.dart
|   |   |   |-- widgets
|   |   |   |   `-- glass_floating_nav_bar.dart
|   |   |   `-- navigation_bottom.dart
|   |   |-- splash
|   |   |   `-- splash_screen.dart
|   |   |-- app.dart
|   |   |-- bootstrap.dart
|   |   `-- navigation_bloc.dart
|   |-- core
|   |   |-- base
|   |   |   `-- stream_repository.dart
|   |   |-- cache
|   |   |   |-- image_cache.dart
|   |   |   |-- local_cache_store.dart
|   |   |   `-- ttl_cache.dart
|   |   |-- config
|   |   |   `-- supabase_config.dart
|   |   |-- constants
|   |   |   |-- api_constant.dart
|   |   |   |-- app_colors.dart
|   |   |   |-- colors.dart
|   |   |   |-- enum.dart
|   |   |   |-- image_string.dart
|   |   |   |-- sizes.dart
|   |   |   `-- text.dart
|   |   |-- devices
|   |   |   `-- device_utility.dart
|   |   |-- di
|   |   |   `-- injection.dart
|   |   |-- helpers
|   |   |   |-- class_type_colors.dart
|   |   |   |-- coach_photo_helper.dart
|   |   |   |-- helper_function.dart
|   |   |   |-- image_resize_helper.dart
|   |   |   |-- payment_reference_helper.dart
|   |   |   |-- payment_screenshot_helper.dart
|   |   |   |-- pricing_calculator.dart
|   |   |   |-- session_live_status.dart
|   |   |   |-- session_schedule_helper.dart
|   |   |   |-- session_smart_defaults.dart
|   |   |   |-- subscription_formatters.dart
|   |   |   `-- subscription_pricing.dart
|   |   |-- search
|   |   |   |-- search_cubit.dart
|   |   |   `-- search_query_cubit.dart
|   |   |-- services
|   |   |   |-- admin_tab_controller.dart
|   |   |   |-- firebase_messaging_service.dart
|   |   |   |-- main_tab_controller.dart
|   |   |   |-- member_data_prefetch.dart
|   |   |   |-- member_data_sync.dart
|   |   |   `-- user_qr_service.dart
|   |   |-- theme
|   |   |   |-- custom_theme
|   |   |   |   |-- appbar_theme.dart
|   |   |   |   |-- bottom_sheet_theme.dart
|   |   |   |   |-- button_theme.dart
|   |   |   |   |-- checkbox_theme.dart
|   |   |   |   |-- chip_theme.dart
|   |   |   |   |-- outlined_button_theme.dart
|   |   |   |   |-- text_field_theme.dart
|   |   |   |   `-- text_theme.dart
|   |   |   |-- app_gradients.dart
|   |   |   |-- splach_theme.dart
|   |   |   `-- theme.dart
|   |   |-- utils
|   |   |   `-- validators.dart
|   |   |-- validators
|   |   |   `-- validation.dart
|   |   `-- widgets
|   |       |-- app_search_bar.dart
|   |       |-- branded_pull_to_refresh.dart
|   |       |-- custom_snackbar.dart
|   |       |-- offline_banner.dart
|   |       |-- semi_circular_gauge.dart
|   |       `-- shimmer_widgets.dart
|   |-- features
|   |   |-- admin
|   |   |   |-- data
|   |   |   |   |-- datasources
|   |   |   |   |   `-- admin_session_preferences.dart
|   |   |   |   |-- mappers
|   |   |   |   |   `-- tracking_data_mapper.dart
|   |   |   |   |-- models
|   |   |   |   |   |-- active_user_model.dart
|   |   |   |   |   |-- admin_dashboard_model.dart
|   |   |   |   |   |-- admin_scan_profile_model.dart
|   |   |   |   |   |-- attendance_record_model.dart
|   |   |   |   |   |-- branch_model.dart
|   |   |   |   |   |-- coach_model.dart
|   |   |   |   |   |-- coach_tracking_overview_model.dart
|   |   |   |   |   |-- coach_user_stats_model.dart
|   |   |   |   |   |-- coach_with_sessions.dart
|   |   |   |   |   |-- day_attendance_model.dart
|   |   |   |   |   |-- paged_result.dart
|   |   |   |   |   |-- payment_verification_data.dart
|   |   |   |   |   |-- pending_payment_model.dart
|   |   |   |   |   |-- session_conflict_info.dart
|   |   |   |   |   |-- session_detail_model.dart
|   |   |   |   |   |-- session_draft.dart
|   |   |   |   |   |-- session_draft_mapper.dart
|   |   |   |   |   |-- subscriber_tracking_model.dart
|   |   |   |   |   |-- today_booking_model.dart
|   |   |   |   |   |-- user_booking_detail_model.dart
|   |   |   |   |   |-- user_qr_profile_model.dart
|   |   |   |   |   `-- user_tracking_detail_model.dart
|   |   |   |   `-- repositories
|   |   |   |       |-- admin_dashboard_repository.dart
|   |   |   |       |-- admin_repository.dart
|   |   |   |       |-- branch_repository.dart
|   |   |   |       |-- coach_repository.dart
|   |   |   |       `-- finance_repository.dart
|   |   |   `-- presentation
|   |   |       |-- bloc
|   |   |       |   |-- admin_home
|   |   |       |   |   |-- admin_home_bloc.dart
|   |   |       |   |   |-- admin_home_event.dart
|   |   |       |   |   `-- admin_home_state.dart
|   |   |       |   |-- coach
|   |   |       |   |   |-- coach_bloc.dart
|   |   |       |   |   |-- coach_event.dart
|   |   |       |   |   `-- coach_state.dart
|   |   |       |   |-- dashboard
|   |   |       |   |-- members
|   |   |       |   |   |-- members_list_cubit.dart
|   |   |       |   |   `-- members_list_state.dart
|   |   |       |   |-- today_sessions
|   |   |       |   |   |-- today_sessions_cubit.dart
|   |   |       |   |   `-- today_sessions_state.dart
|   |   |       |   |-- tracking
|   |   |       |   |   |-- tracking_bloc.dart
|   |   |       |   |   |-- tracking_event.dart
|   |   |       |   |   `-- tracking_state.dart
|   |   |       |   |-- admin_bloc.dart
|   |   |       |   |-- admin_dashboard_cubit.dart
|   |   |       |   |-- admin_event.dart
|   |   |       |   |-- admin_state.dart
|   |   |       |   |-- finance_bloc.dart
|   |   |       |   |-- session_detail_bloc.dart
|   |   |       |   |-- session_detail_event.dart
|   |   |       |   `-- session_detail_state.dart
|   |   |       |-- helpers
|   |   |       |   |-- admin_session_form_helper.dart
|   |   |       |   `-- session_conflict_detector.dart
|   |   |       |-- pages
|   |   |       |   |-- tracking
|   |   |       |   |   |-- all_coaches_page.dart
|   |   |       |   |   |-- all_members_page.dart
|   |   |       |   |   |-- tracking_page.dart
|   |   |       |   |   `-- user_tracking_detail_page.dart
|   |   |       |   |-- admin_add_info_page.dart
|   |   |       |   |-- admin_dashboard_page.dart
|   |   |       |   |-- admin_home.dart
|   |   |       |   |-- admin_profile.dart
|   |   |       |   |-- edit_coach_page.dart
|   |   |       |   |-- edit_session_page.dart
|   |   |       |   |-- finance_page.dart
|   |   |       |   |-- payment_verification_page.dart
|   |   |       |   |-- pending_payments_page.dart
|   |   |       |   |-- qr_scanner_page.dart
|   |   |       |   |-- scanned_user_profile.dart
|   |   |       |   |-- session_detail_page.dart
|   |   |       |   `-- today_sessions_page.dart
|   |   |       `-- widgets
|   |   |           |-- admin_home
|   |   |           |   `-- admin_empty_state.dart
|   |   |           |-- dashboard
|   |   |           |   |-- dashboard_attention_list.dart
|   |   |           |   |-- dashboard_header.dart
|   |   |           |   |-- dashboard_kpi_grid.dart
|   |   |           |   |-- dashboard_quick_actions.dart
|   |   |           |   `-- dashboard_today_list.dart
|   |   |           |-- tracking
|   |   |           |   |-- coach_overview_card.dart
|   |   |           |   |-- coach_overview_section.dart
|   |   |           |   |-- subscriber_tracking_card.dart
|   |   |           |   |-- tracking_search_bar.dart
|   |   |           |   `-- weekly_attendance_grid.dart
|   |   |           |-- admin_autocomplete_field.dart
|   |   |           |-- admin_coach_booking_filter_chips.dart
|   |   |           |-- admin_dashed_upload.dart
|   |   |           |-- admin_dismissible_card.dart
|   |   |           |-- admin_dropdown_field.dart
|   |   |           |-- admin_form_styles.dart
|   |   |           |-- admin_header.dart
|   |   |           |-- admin_member_booking_list_helpers.dart
|   |   |           |-- admin_member_profile_header.dart
|   |   |           |-- admin_multi_select_dropdown.dart
|   |   |           |-- admin_searchable_dropdown_field.dart
|   |   |           |-- admin_section_card.dart
|   |   |           |-- admin_session_list_tile.dart
|   |   |           |-- admin_smooth_scroll.dart
|   |   |           |-- admin_tab_layout.dart
|   |   |           |-- admin_tab_selector.dart
|   |   |           |-- admin_text_field.dart
|   |   |           |-- branch_badge.dart
|   |   |           |-- branch_management_dialog.dart
|   |   |           |-- branch_selector_field.dart
|   |   |           |-- class_type_filter_dropdown.dart
|   |   |           |-- coach_avatar.dart
|   |   |           |-- coach_avatar_with_verify_icon.dart
|   |   |           |-- coach_card.dart
|   |   |           |-- coach_name_with_verify.dart
|   |   |           |-- custom_bottom_navigation.dart
|   |   |           |-- delete_confirmation_sheet.dart
|   |   |           |-- member_booking_card.dart
|   |   |           |-- multi_select_chip_row.dart
|   |   |           |-- payment_method_filter.dart
|   |   |           |-- payment_screenshot_viewer.dart
|   |   |           |-- payment_verification_sheet.dart
|   |   |           |-- pending_payment_card.dart
|   |   |           |-- reject_payment_dialog.dart
|   |   |           |-- session_card.dart
|   |   |           |-- session_conflict_dialog.dart
|   |   |           |-- session_draft_row.dart
|   |   |           |-- session_frequency_selector.dart
|   |   |           |-- specialty_chip.dart
|   |   |           `-- today_session_card.dart
|   |   |-- auth
|   |   |   |-- data
|   |   |   |   |-- datasources
|   |   |   |   |   `-- auth_remote_ds.dart
|   |   |   |   |-- models
|   |   |   |   |   `-- app_user.dart
|   |   |   |   `-- repositories
|   |   |   |       `-- auth_repo_impl.dart
|   |   |   |-- domain
|   |   |   |   `-- repositories
|   |   |   |       `-- auth_repo.dart
|   |   |   `-- presentation
|   |   |       |-- bloc
|   |   |       |   |-- auth_bloc.dart
|   |   |       |   |-- auth_event.dart
|   |   |       |   `-- auth_state.dart
|   |   |       `-- pages
|   |   |           |-- auth
|   |   |           |   |-- common_widgets
|   |   |           |   |   |-- divider.dart
|   |   |           |   |   `-- social_button.dart
|   |   |           |   |-- login
|   |   |           |   |   |-- widgets
|   |   |           |   |   |   |-- login_form.dart
|   |   |           |   |   |   `-- login_header.dart
|   |   |           |   |   `-- login.dart
|   |   |           |   `-- signup
|   |   |           |       |-- widgets
|   |   |           |       |   |-- signup_form.dart
|   |   |           |       |   |-- signup_header.dart
|   |   |           |       |   `-- signup_text.dart
|   |   |           |       `-- signup.dart
|   |   |           `-- authentication
|   |   |               |-- widgets
|   |   |               |   |-- auth_background.dart
|   |   |               |   |-- auth_card.dart
|   |   |               |   |-- auth_tab_bar.dart
|   |   |               |   |-- auth_text_field.dart
|   |   |               |   `-- gradient_button.dart
|   |   |               `-- auth_page.dart
|   |   |-- booking
|   |   |   |-- data
|   |   |   |   |-- datasources
|   |   |   |   |   `-- booking_remote_ds.dart
|   |   |   |   |-- models
|   |   |   |   |   |-- booking_history_model.dart
|   |   |   |   |   `-- booking_model.dart
|   |   |   |   `-- repositories
|   |   |   |       `-- booking_repository.dart
|   |   |   `-- presentation
|   |   |       |-- bloc
|   |   |       |   |-- booking_bloc.dart
|   |   |       |   |-- booking_detail_bloc.dart
|   |   |       |   |-- booking_detail_event.dart
|   |   |       |   |-- booking_detail_state.dart
|   |   |       |   |-- booking_event.dart
|   |   |       |   |-- booking_history_bloc.dart
|   |   |       |   |-- booking_history_event.dart
|   |   |       |   |-- booking_history_state.dart
|   |   |       |   `-- booking_state.dart
|   |   |       |-- helpers
|   |   |       |   `-- book_now_navigation.dart
|   |   |       |-- pages
|   |   |       |   |-- booking
|   |   |       |   |   `-- booking_screen.dart
|   |   |       |   |-- booking_details
|   |   |       |   |   |-- widgets
|   |   |       |   |   |   |-- booking_bottom_bar.dart
|   |   |       |   |   |   |-- booking_total_card.dart
|   |   |       |   |   |   |-- coach_header_card.dart
|   |   |       |   |   |   |-- payment_method_selector.dart
|   |   |       |   |   |   `-- schedule_selector.dart
|   |   |       |   |   |-- booking.dart
|   |   |       |   |   |-- booking_detail_page.dart
|   |   |       |   |   `-- booking_success_screen.dart
|   |   |       |   |-- booking_history_page.dart
|   |   |       |   `-- booking_page.dart
|   |   |       `-- widgets
|   |   |           |-- already_booked_button.dart
|   |   |           |-- booking_confirmation_dialog.dart
|   |   |           |-- branch_picker_sheet.dart
|   |   |           |-- calendar_schedule_picker.dart
|   |   |           |-- day_selector.dart
|   |   |           |-- instapay_payment_sheet.dart
|   |   |           `-- payment_method_sheet.dart
|   |   |-- home
|   |   |   |-- data
|   |   |   |   |-- models
|   |   |   |   |   |-- catgeory_model.dart
|   |   |   |   |   |-- coach_session_model.dart
|   |   |   |   |   `-- coaches_model.dart
|   |   |   |   `-- repositories
|   |   |   |       `-- home_coach_repository.dart
|   |   |   `-- presentation
|   |   |       |-- bloc
|   |   |       |   |-- home_bloc.dart
|   |   |       |   |-- home_event.dart
|   |   |       |   `-- home_state.dart
|   |   |       |-- pages
|   |   |       |   |-- home
|   |   |       |   |   |-- widgets
|   |   |       |   |   |   |-- category_list.dart
|   |   |       |   |   |   |-- coaches_list.dart
|   |   |       |   |   |   |-- home_coach_card.dart
|   |   |       |   |   |   |-- searchbar.dart
|   |   |       |   |   |   `-- session_info_card.dart
|   |   |       |   |   |-- coach_profile.dart
|   |   |       |   |   `-- home.dart
|   |   |       |   |-- coaches_page.dart
|   |   |       |   `-- home_page.dart
|   |   |       `-- widgets
|   |   |           |-- calendar_strip.dart
|   |   |           |-- date_header.dart
|   |   |           |-- date_strip.dart
|   |   |           |-- first_time_booking_card.dart
|   |   |           |-- last_booking_card.dart
|   |   |           |-- location_card.dart
|   |   |           |-- map_card.dart
|   |   |           |-- recent_activity.dart
|   |   |           `-- upcoming_session_card.dart
|   |   |-- maps
|   |   |   |-- data
|   |   |   |   `-- models
|   |   |   |       `-- maps_model.dart
|   |   |   `-- presentation
|   |   |       `-- pages
|   |   |           `-- maps
|   |   |               |-- widgets
|   |   |               |   `-- maps.dart
|   |   |               `-- map_page.dart
|   |   |-- notifications
|   |   |   |-- data
|   |   |   |   |-- models
|   |   |   |   |   `-- app_notification.dart
|   |   |   |   `-- repositories
|   |   |   |       `-- notification_repository.dart
|   |   |   `-- presentation
|   |   |       |-- bloc
|   |   |       |   |-- notification_bloc.dart
|   |   |       |   |-- notification_event.dart
|   |   |       |   `-- notification_state.dart
|   |   |       |-- pages
|   |   |       |   `-- notifications_page.dart
|   |   |       `-- widgets
|   |   |           `-- notification_bell_button.dart
|   |   |-- profile
|   |   |   `-- presentation
|   |   |       |-- pages
|   |   |       |   `-- profile
|   |   |       |       |-- edit_profile_page.dart
|   |   |       |       |-- my_qr_screen.dart
|   |   |       |       |-- payments_page.dart
|   |   |       |       `-- profile.dart
|   |   |       `-- widgets
|   |   |           |-- member_qr_display.dart
|   |   |           `-- qr_code_bottom_sheet.dart
|   |   `-- sessions
|   |       |-- data
|   |       |   |-- models
|   |       |   |   |-- calendar_session_model.dart
|   |       |   |   |-- coach_summary_model.dart
|   |       |   |   `-- session_model.dart
|   |       |   `-- repositories
|   |       |       `-- sessions_repository.dart
|   |       |-- domain
|   |       |   |-- weekly_progress_calculator.dart
|   |       |   `-- weekly_progress_summary.dart
|   |       |-- presentation
|   |       |   |-- bloc
|   |       |   |   |-- sessions_bloc.dart
|   |       |   |   |-- sessions_event.dart
|   |       |   |   |-- sessions_state.dart
|   |       |   |   |-- user_session_detail_bloc.dart
|   |       |   |   `-- user_session_detail_event.dart
|   |       |   |-- models
|   |       |   |-- pages
|   |       |   |   |-- sessions_page.dart
|   |       |   |   `-- user_session_detail_page.dart
|   |       |   `-- widgets
|   |       |       |-- booking_session_card.dart
|   |       |       |-- coach_chip_list.dart
|   |       |       |-- progress_card.dart
|   |       |       |-- session_card.dart
|   |       |       |-- sessions_month_calendar.dart
|   |       |       |-- sessions_tab_bar.dart
|   |       |       `-- weekly_attendance_chart.dart
|   |       `-- session_screen.dart
|   |-- shared
|   |   `-- primary_button.dart
|   |-- view
|   |   `-- bottom_navigation
|   |       `-- navigation_bottom.dart
|   |-- firebase_options.dart
|   `-- main.dart
|-- linux
|   |-- flutter
|   |   |-- ephemeral
|   |   |   `-- .plugin_symlinks
|   |   |       |-- app_links_linux
|   |   |       |   |-- lib
|   |   |       |   |   `-- app_links_linux.dart
|   |   |       |   |-- analysis_options.yaml
|   |   |       |   |-- CHANGELOG.md
|   |   |       |   |-- LICENSE
|   |   |       |   |-- pubspec.yaml
|   |   |       |   `-- README.md
|   |   |       |-- file_selector_linux
|   |   |       |   |-- example
|   |   |       |   |   |-- lib
|   |   |       |   |   |   |-- get_directory_page.dart
|   |   |       |   |   |   |-- get_multiple_directories_page.dart
|   |   |       |   |   |   |-- home_page.dart
|   |   |       |   |   |   |-- main.dart
|   |   |       |   |   |   |-- open_image_page.dart
|   |   |       |   |   |   |-- open_multiple_images_page.dart
|   |   |       |   |   |   |-- open_text_page.dart
|   |   |       |   |   |   `-- save_text_page.dart
|   |   |       |   |   |-- linux
|   |   |       |   |   |   |-- flutter
|   |   |       |   |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |   `-- generated_plugins.cmake
|   |   |       |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |-- main.cc
|   |   |       |   |   |   |-- my_application.cc
|   |   |       |   |   |   `-- my_application.h
|   |   |       |   |   |-- pubspec.yaml
|   |   |       |   |   `-- README.md
|   |   |       |   |-- lib
|   |   |       |   |   `-- file_selector_linux.dart
|   |   |       |   |-- linux
|   |   |       |   |   |-- include
|   |   |       |   |   |   `-- file_selector_linux
|   |   |       |   |   |       `-- file_selector_plugin.h
|   |   |       |   |   |-- test
|   |   |       |   |   |   |-- file_selector_plugin_test.cc
|   |   |       |   |   |   `-- test_main.cc
|   |   |       |   |   |-- CMakeLists.txt
|   |   |       |   |   |-- file_selector_plugin.cc
|   |   |       |   |   `-- file_selector_plugin_private.h
|   |   |       |   |-- test
|   |   |       |   |   `-- file_selector_linux_test.dart
|   |   |       |   |-- AUTHORS
|   |   |       |   |-- CHANGELOG.md
|   |   |       |   |-- LICENSE
|   |   |       |   |-- pubspec.yaml
|   |   |       |   `-- README.md
|   |   |       |-- gtk
|   |   |       |   |-- example
|   |   |       |   |   |-- lib
|   |   |       |   |   |   `-- main.dart
|   |   |       |   |   |-- linux
|   |   |       |   |   |   |-- flutter
|   |   |       |   |   |   |   `-- CMakeLists.txt
|   |   |       |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |-- main.cc
|   |   |       |   |   |   |-- my_application.cc
|   |   |       |   |   |   `-- my_application.h
|   |   |       |   |   |-- web
|   |   |       |   |   |   |-- icons
|   |   |       |   |   |   |   |-- Icon-192.png
|   |   |       |   |   |   |   |-- Icon-512.png
|   |   |       |   |   |   |   |-- Icon-maskable-192.png
|   |   |       |   |   |   |   `-- Icon-maskable-512.png
|   |   |       |   |   |   |-- favicon.png
|   |   |       |   |   |   |-- index.html
|   |   |       |   |   |   `-- manifest.json
|   |   |       |   |   |-- analysis_options.yaml
|   |   |       |   |   |-- pubspec.yaml
|   |   |       |   |   |-- pubspec_overrides.yaml
|   |   |       |   |   |-- README.md
|   |   |       |   |   `-- screenshot.png
|   |   |       |   |-- lib
|   |   |       |   |   |-- src
|   |   |       |   |   |   |-- constants.dart
|   |   |       |   |   |   |-- gtk_application.dart
|   |   |       |   |   |   |-- gtk_application_notifier.dart
|   |   |       |   |   |   |-- gtk_settings.dart
|   |   |       |   |   |   |-- gtk_settings_real.dart
|   |   |       |   |   |   |-- gtk_settings_stub.dart
|   |   |       |   |   |   |-- libgtk.dart
|   |   |       |   |   |   `-- libgtk.g.dart
|   |   |       |   |   `-- gtk.dart
|   |   |       |   |-- linux
|   |   |       |   |   |-- include
|   |   |       |   |   |   `-- gtk
|   |   |       |   |   |       `-- gtk_plugin.h
|   |   |       |   |   |-- CMakeLists.txt
|   |   |       |   |   `-- gtk_plugin.cc
|   |   |       |   |-- test
|   |   |       |   |   |-- gtk_application_notifier_test.dart
|   |   |       |   |   |-- gtk_application_test.dart
|   |   |       |   |   |-- gtk_settings_test.dart
|   |   |       |   |   |-- test_utils.dart
|   |   |       |   |   `-- test_utils.mocks.dart
|   |   |       |   |-- CHANGELOG.md
|   |   |       |   |-- codecov.yaml
|   |   |       |   |-- ffigen.yaml
|   |   |       |   |-- LICENSE
|   |   |       |   |-- pubspec.yaml
|   |   |       |   |-- README.md
|   |   |       |   `-- renovate.json
|   |   |       |-- image_picker_linux
|   |   |       |   |-- example
|   |   |       |   |   |-- lib
|   |   |       |   |   |   `-- main.dart
|   |   |       |   |   |-- linux
|   |   |       |   |   |   |-- flutter
|   |   |       |   |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |   `-- generated_plugins.cmake
|   |   |       |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |-- main.cc
|   |   |       |   |   |   |-- my_application.cc
|   |   |       |   |   |   `-- my_application.h
|   |   |       |   |   |-- pubspec.yaml
|   |   |       |   |   `-- README.md
|   |   |       |   |-- lib
|   |   |       |   |   `-- image_picker_linux.dart
|   |   |       |   |-- test
|   |   |       |   |   |-- image_picker_linux_test.dart
|   |   |       |   |   `-- image_picker_linux_test.mocks.dart
|   |   |       |   |-- AUTHORS
|   |   |       |   |-- CHANGELOG.md
|   |   |       |   |-- LICENSE
|   |   |       |   |-- pubspec.yaml
|   |   |       |   `-- README.md
|   |   |       |-- path_provider_linux
|   |   |       |   |-- example
|   |   |       |   |   |-- integration_test
|   |   |       |   |   |   `-- path_provider_test.dart
|   |   |       |   |   |-- lib
|   |   |       |   |   |   `-- main.dart
|   |   |       |   |   |-- linux
|   |   |       |   |   |   |-- flutter
|   |   |       |   |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |   `-- generated_plugins.cmake
|   |   |       |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |-- main.cc
|   |   |       |   |   |   |-- my_application.cc
|   |   |       |   |   |   `-- my_application.h
|   |   |       |   |   |-- test_driver
|   |   |       |   |   |   `-- integration_test.dart
|   |   |       |   |   |-- pubspec.yaml
|   |   |       |   |   `-- README.md
|   |   |       |   |-- lib
|   |   |       |   |   |-- src
|   |   |       |   |   |   |-- get_application_id.dart
|   |   |       |   |   |   |-- get_application_id_real.dart
|   |   |       |   |   |   |-- get_application_id_stub.dart
|   |   |       |   |   |   `-- path_provider_linux.dart
|   |   |       |   |   `-- path_provider_linux.dart
|   |   |       |   |-- test
|   |   |       |   |   |-- get_application_id_test.dart
|   |   |       |   |   `-- path_provider_linux_test.dart
|   |   |       |   |-- AUTHORS
|   |   |       |   |-- CHANGELOG.md
|   |   |       |   |-- LICENSE
|   |   |       |   |-- pubspec.yaml
|   |   |       |   `-- README.md
|   |   |       |-- shared_preferences_linux
|   |   |       |   |-- example
|   |   |       |   |   |-- integration_test
|   |   |       |   |   |   `-- shared_preferences_test.dart
|   |   |       |   |   |-- lib
|   |   |       |   |   |   `-- main.dart
|   |   |       |   |   |-- linux
|   |   |       |   |   |   |-- flutter
|   |   |       |   |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |   `-- generated_plugins.cmake
|   |   |       |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |-- main.cc
|   |   |       |   |   |   |-- my_application.cc
|   |   |       |   |   |   `-- my_application.h
|   |   |       |   |   |-- test_driver
|   |   |       |   |   |   `-- integration_test.dart
|   |   |       |   |   |-- pubspec.yaml
|   |   |       |   |   `-- README.md
|   |   |       |   |-- lib
|   |   |       |   |   `-- shared_preferences_linux.dart
|   |   |       |   |-- test
|   |   |       |   |   |-- fake_path_provider_linux.dart
|   |   |       |   |   |-- legacy_shared_preferences_linux_test.dart
|   |   |       |   |   `-- shared_preferences_linux_async_test.dart
|   |   |       |   |-- AUTHORS
|   |   |       |   |-- CHANGELOG.md
|   |   |       |   |-- LICENSE
|   |   |       |   |-- pubspec.yaml
|   |   |       |   `-- README.md
|   |   |       `-- url_launcher_linux
|   |   |           |-- example
|   |   |           |   |-- integration_test
|   |   |           |   |   `-- url_launcher_test.dart
|   |   |           |   |-- lib
|   |   |           |   |   `-- main.dart
|   |   |           |   |-- linux
|   |   |           |   |   |-- flutter
|   |   |           |   |   |   |-- CMakeLists.txt
|   |   |           |   |   |   `-- generated_plugins.cmake
|   |   |           |   |   |-- CMakeLists.txt
|   |   |           |   |   |-- main.cc
|   |   |           |   |   |-- my_application.cc
|   |   |           |   |   `-- my_application.h
|   |   |           |   |-- test_driver
|   |   |           |   |   `-- integration_test.dart
|   |   |           |   |-- pubspec.yaml
|   |   |           |   `-- README.md
|   |   |           |-- lib
|   |   |           |   `-- url_launcher_linux.dart
|   |   |           |-- linux
|   |   |           |   |-- include
|   |   |           |   |   `-- url_launcher_linux
|   |   |           |   |       `-- url_launcher_plugin.h
|   |   |           |   |-- test
|   |   |           |   |   `-- url_launcher_linux_test.cc
|   |   |           |   |-- CMakeLists.txt
|   |   |           |   |-- url_launcher_plugin.cc
|   |   |           |   `-- url_launcher_plugin_private.h
|   |   |           |-- test
|   |   |           |   `-- url_launcher_linux_test.dart
|   |   |           |-- AUTHORS
|   |   |           |-- CHANGELOG.md
|   |   |           |-- LICENSE
|   |   |           |-- pubspec.yaml
|   |   |           `-- README.md
|   |   |-- CMakeLists.txt
|   |   |-- generated_plugin_registrant.cc
|   |   |-- generated_plugin_registrant.h
|   |   `-- generated_plugins.cmake
|   |-- .gitignore
|   |-- CMakeLists.txt
|   |-- main.cc
|   |-- my_application.cc
|   `-- my_application.h
|-- macos
|   |-- Flutter
|   |   |-- ephemeral
|   |   |   |-- flutter_export_environment.sh
|   |   |   `-- Flutter-Generated.xcconfig
|   |   |-- Flutter-Debug.xcconfig
|   |   |-- Flutter-Release.xcconfig
|   |   `-- GeneratedPluginRegistrant.swift
|   |-- Runner
|   |   |-- Assets.xcassets
|   |   |   `-- AppIcon.appiconset
|   |   |       |-- app_icon_1024.png
|   |   |       |-- app_icon_128.png
|   |   |       |-- app_icon_16.png
|   |   |       |-- app_icon_256.png
|   |   |       |-- app_icon_32.png
|   |   |       |-- app_icon_512.png
|   |   |       |-- app_icon_64.png
|   |   |       `-- Contents.json
|   |   |-- Base.lproj
|   |   |   `-- MainMenu.xib
|   |   |-- Configs
|   |   |   |-- AppInfo.xcconfig
|   |   |   |-- Debug.xcconfig
|   |   |   |-- Release.xcconfig
|   |   |   `-- Warnings.xcconfig
|   |   |-- AppDelegate.swift
|   |   |-- DebugProfile.entitlements
|   |   |-- Info.plist
|   |   |-- MainFlutterWindow.swift
|   |   `-- Release.entitlements
|   |-- Runner.xcodeproj
|   |   |-- project.xcworkspace
|   |   |   `-- xcshareddata
|   |   |       `-- IDEWorkspaceChecks.plist
|   |   |-- xcshareddata
|   |   |   `-- xcschemes
|   |   |       `-- Runner.xcscheme
|   |   `-- project.pbxproj
|   |-- Runner.xcworkspace
|   |   |-- xcshareddata
|   |   |   `-- IDEWorkspaceChecks.plist
|   |   `-- contents.xcworkspacedata
|   |-- RunnerTests
|   |   `-- RunnerTests.swift
|   |-- .gitignore
|   |-- Podfile
|   `-- Podfile.lock
|-- snap
|   `-- gui
|       |-- app_icon.desktop
|       `-- app_icon.png
|-- supabase
|   |-- admin_scan_profile.sql
|   |-- attendance_session_management.sql
|   |-- booking_flow.sql
|   |-- booking_monthly_pricing.sql
|   |-- cap_user_sessions_history.sql
|   |-- coach_member_count.sql
|   |-- coach_photos_storage.sql
|   |-- coach_sessions_duration.sql
|   |-- coach_sessions_setup.sql
|   |-- fix_booking_payment_status.sql
|   |-- fix_re_attend_updated_at.sql
|   |-- fix_session_conflict_branch_day_time.sql
|   |-- fix_sessions_rpc_type_mismatch.sql
|   |-- fix_signup_trigger.sql
|   |-- fix_user_sessions_visibility.sql
|   |-- get_active_users_page.sql
|   |-- notifications_fcm_token.sql
|   |-- payment_screenshots_storage.sql
|   |-- performance_indexes.sql
|   |-- profile_avatars.sql
|   |-- profiles_rls_fix.sql
|   |-- today_coach_sessions.sql
|   `-- user_booking_actions.sql
|-- test
|   |-- paged_result_test.dart
|   |-- session_conflict_detector_test.dart
|   `-- widget_test.dart
|-- tool
|   `-- compress_assets.dart
|-- web
|   |-- icons
|   |   |-- Icon-192.png
|   |   |-- Icon-512.png
|   |   |-- Icon-maskable-192.png
|   |   `-- Icon-maskable-512.png
|   |-- favicon.png
|   |-- index.html
|   `-- manifest.json
|-- windows
|   |-- flutter
|   |   |-- ephemeral
|   |   |   `-- .plugin_symlinks
|   |   |       |-- app_links
|   |   |       |   |-- android
|   |   |       |   |   |-- gradle
|   |   |       |   |   |   `-- wrapper
|   |   |       |   |   |       `-- gradle-wrapper.properties
|   |   |       |   |   |-- src
|   |   |       |   |   |   `-- main
|   |   |       |   |   |       |-- java
|   |   |       |   |   |       |   `-- com
|   |   |       |   |   |       |       `-- llfbandit
|   |   |       |   |   |       |           `-- app_links
|   |   |       |   |   |       |               |-- AppLinksHelper.java
|   |   |       |   |   |       |               `-- AppLinksPlugin.java
|   |   |       |   |   |       `-- AndroidManifest.xml
|   |   |       |   |   |-- build.gradle
|   |   |       |   |   |-- gradle.properties
|   |   |       |   |   `-- settings.gradle
|   |   |       |   |-- example
|   |   |       |   |   |-- android
|   |   |       |   |   |   |-- app
|   |   |       |   |   |   |   |-- src
|   |   |       |   |   |   |   |   |-- debug
|   |   |       |   |   |   |   |   |   `-- AndroidManifest.xml
|   |   |       |   |   |   |   |   |-- main
|   |   |       |   |   |   |   |   |   |-- java
|   |   |       |   |   |   |   |   |   |   |-- com
|   |   |       |   |   |   |   |   |   |   |   `-- llfbandit
|   |   |       |   |   |   |   |   |   |   |       `-- app_links_example
|   |   |       |   |   |   |   |   |   |   |           `-- MainActivity.java
|   |   |       |   |   |   |   |   |   |   `-- io
|   |   |       |   |   |   |   |   |   |       `-- flutter
|   |   |       |   |   |   |   |   |   |           `-- plugins
|   |   |       |   |   |   |   |   |   |               `-- GeneratedPluginRegistrant.java
|   |   |       |   |   |   |   |   |   |-- kotlin
|   |   |       |   |   |   |   |   |   |   `-- com
|   |   |       |   |   |   |   |   |   |       `-- llfbandit
|   |   |       |   |   |   |   |   |   |           `-- example
|   |   |       |   |   |   |   |   |   |               `-- MainActivity.kt
|   |   |       |   |   |   |   |   |   |-- res
|   |   |       |   |   |   |   |   |   |   |-- drawable
|   |   |       |   |   |   |   |   |   |   |   `-- launch_background.xml
|   |   |       |   |   |   |   |   |   |   |-- drawable-v21
|   |   |       |   |   |   |   |   |   |   |   `-- launch_background.xml
|   |   |       |   |   |   |   |   |   |   |-- mipmap-hdpi
|   |   |       |   |   |   |   |   |   |   |   `-- ic_launcher.png
|   |   |       |   |   |   |   |   |   |   |-- mipmap-mdpi
|   |   |       |   |   |   |   |   |   |   |   `-- ic_launcher.png
|   |   |       |   |   |   |   |   |   |   |-- mipmap-xhdpi
|   |   |       |   |   |   |   |   |   |   |   `-- ic_launcher.png
|   |   |       |   |   |   |   |   |   |   |-- mipmap-xxhdpi
|   |   |       |   |   |   |   |   |   |   |   `-- ic_launcher.png
|   |   |       |   |   |   |   |   |   |   |-- mipmap-xxxhdpi
|   |   |       |   |   |   |   |   |   |   |   `-- ic_launcher.png
|   |   |       |   |   |   |   |   |   |   |-- values
|   |   |       |   |   |   |   |   |   |   |   `-- styles.xml
|   |   |       |   |   |   |   |   |   |   `-- values-night
|   |   |       |   |   |   |   |   |   |       `-- styles.xml
|   |   |       |   |   |   |   |   |   `-- AndroidManifest.xml
|   |   |       |   |   |   |   |   `-- profile
|   |   |       |   |   |   |   |       `-- AndroidManifest.xml
|   |   |       |   |   |   |   `-- build.gradle
|   |   |       |   |   |   |-- gradle
|   |   |       |   |   |   |   `-- wrapper
|   |   |       |   |   |   |       |-- gradle-wrapper.jar
|   |   |       |   |   |   |       `-- gradle-wrapper.properties
|   |   |       |   |   |   |-- build.gradle
|   |   |       |   |   |   |-- gradle.properties
|   |   |       |   |   |   |-- gradlew
|   |   |       |   |   |   |-- gradlew.bat
|   |   |       |   |   |   `-- settings.gradle
|   |   |       |   |   |-- ios
|   |   |       |   |   |   |-- Flutter
|   |   |       |   |   |   |   |-- AppFrameworkInfo.plist
|   |   |       |   |   |   |   |-- Debug.xcconfig
|   |   |       |   |   |   |   `-- Release.xcconfig
|   |   |       |   |   |   |-- Runner
|   |   |       |   |   |   |   |-- Assets.xcassets
|   |   |       |   |   |   |   |   |-- AppIcon.appiconset
|   |   |       |   |   |   |   |   |   |-- Contents.json
|   |   |       |   |   |   |   |   |   |-- Icon-App-1024x1024@1x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-20x20@1x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-20x20@2x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-20x20@3x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-29x29@1x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-29x29@2x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-29x29@3x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-40x40@1x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-40x40@2x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-40x40@3x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-60x60@2x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-60x60@3x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-76x76@1x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-76x76@2x.png
|   |   |       |   |   |   |   |   |   `-- Icon-App-83.5x83.5@2x.png
|   |   |       |   |   |   |   |   `-- LaunchImage.imageset
|   |   |       |   |   |   |   |       |-- Contents.json
|   |   |       |   |   |   |   |       |-- LaunchImage.png
|   |   |       |   |   |   |   |       |-- LaunchImage@2x.png
|   |   |       |   |   |   |   |       |-- LaunchImage@3x.png
|   |   |       |   |   |   |   |       `-- README.md
|   |   |       |   |   |   |   |-- Base.lproj
|   |   |       |   |   |   |   |   |-- LaunchScreen.storyboard
|   |   |       |   |   |   |   |   `-- Main.storyboard
|   |   |       |   |   |   |   |-- AppDelegate.swift
|   |   |       |   |   |   |   |-- Info.plist
|   |   |       |   |   |   |   |-- Runner.entitlements
|   |   |       |   |   |   |   `-- Runner-Bridging-Header.h
|   |   |       |   |   |   |-- Runner.xcodeproj
|   |   |       |   |   |   |   |-- project.xcworkspace
|   |   |       |   |   |   |   |   |-- xcshareddata
|   |   |       |   |   |   |   |   |   |-- IDEWorkspaceChecks.plist
|   |   |       |   |   |   |   |   |   `-- WorkspaceSettings.xcsettings
|   |   |       |   |   |   |   |   `-- contents.xcworkspacedata
|   |   |       |   |   |   |   |-- xcshareddata
|   |   |       |   |   |   |   |   `-- xcschemes
|   |   |       |   |   |   |   |       `-- Runner.xcscheme
|   |   |       |   |   |   |   `-- project.pbxproj
|   |   |       |   |   |   |-- Runner.xcworkspace
|   |   |       |   |   |   |   |-- xcshareddata
|   |   |       |   |   |   |   |   |-- IDEWorkspaceChecks.plist
|   |   |       |   |   |   |   |   `-- WorkspaceSettings.xcsettings
|   |   |       |   |   |   |   `-- contents.xcworkspacedata
|   |   |       |   |   |   |-- Podfile
|   |   |       |   |   |   `-- Podfile.lock
|   |   |       |   |   |-- lib
|   |   |       |   |   |   |-- url_protocol
|   |   |       |   |   |   |   |-- api.dart
|   |   |       |   |   |   |   |-- protocol.dart
|   |   |       |   |   |   |   |-- web_url_protocol.dart
|   |   |       |   |   |   |   `-- windows_protocol.dart
|   |   |       |   |   |   `-- main.dart
|   |   |       |   |   |-- linux
|   |   |       |   |   |   |-- flutter
|   |   |       |   |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |   |-- generated_plugin_registrant.cc
|   |   |       |   |   |   |   |-- generated_plugin_registrant.h
|   |   |       |   |   |   |   `-- generated_plugins.cmake
|   |   |       |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |-- main.cc
|   |   |       |   |   |   |-- my_application.cc
|   |   |       |   |   |   `-- my_application.h
|   |   |       |   |   |-- macos
|   |   |       |   |   |   |-- Flutter
|   |   |       |   |   |   |   |-- Flutter-Debug.xcconfig
|   |   |       |   |   |   |   |-- Flutter-Release.xcconfig
|   |   |       |   |   |   |   `-- GeneratedPluginRegistrant.swift
|   |   |       |   |   |   |-- Runner
|   |   |       |   |   |   |   |-- Assets.xcassets
|   |   |       |   |   |   |   |   `-- AppIcon.appiconset
|   |   |       |   |   |   |   |       |-- app_icon_1024.png
|   |   |       |   |   |   |   |       |-- app_icon_128.png
|   |   |       |   |   |   |   |       |-- app_icon_16.png
|   |   |       |   |   |   |   |       |-- app_icon_256.png
|   |   |       |   |   |   |   |       |-- app_icon_32.png
|   |   |       |   |   |   |   |       |-- app_icon_512.png
|   |   |       |   |   |   |   |       |-- app_icon_64.png
|   |   |       |   |   |   |   |       `-- Contents.json
|   |   |       |   |   |   |   |-- Base.lproj
|   |   |       |   |   |   |   |   `-- MainMenu.xib
|   |   |       |   |   |   |   |-- Configs
|   |   |       |   |   |   |   |   |-- AppInfo.xcconfig
|   |   |       |   |   |   |   |   |-- Debug.xcconfig
|   |   |       |   |   |   |   |   |-- Release.xcconfig
|   |   |       |   |   |   |   |   `-- Warnings.xcconfig
|   |   |       |   |   |   |   |-- AppDelegate.swift
|   |   |       |   |   |   |   |-- DebugProfile.entitlements
|   |   |       |   |   |   |   |-- Info.plist
|   |   |       |   |   |   |   |-- MainFlutterWindow.swift
|   |   |       |   |   |   |   `-- Release.entitlements
|   |   |       |   |   |   |-- Runner.xcodeproj
|   |   |       |   |   |   |   |-- project.xcworkspace
|   |   |       |   |   |   |   |   `-- xcshareddata
|   |   |       |   |   |   |   |       `-- IDEWorkspaceChecks.plist
|   |   |       |   |   |   |   |-- xcshareddata
|   |   |       |   |   |   |   |   `-- xcschemes
|   |   |       |   |   |   |   |       `-- Runner.xcscheme
|   |   |       |   |   |   |   `-- project.pbxproj
|   |   |       |   |   |   |-- Runner.xcworkspace
|   |   |       |   |   |   |   |-- xcshareddata
|   |   |       |   |   |   |   |   `-- IDEWorkspaceChecks.plist
|   |   |       |   |   |   |   `-- contents.xcworkspacedata
|   |   |       |   |   |   |-- Podfile
|   |   |       |   |   |   `-- Podfile.lock
|   |   |       |   |   |-- web
|   |   |       |   |   |   |-- icons
|   |   |       |   |   |   |   |-- Icon-192.png
|   |   |       |   |   |   |   |-- Icon-512.png
|   |   |       |   |   |   |   |-- Icon-maskable-192.png
|   |   |       |   |   |   |   `-- Icon-maskable-512.png
|   |   |       |   |   |   |-- favicon.png
|   |   |       |   |   |   |-- index.html
|   |   |       |   |   |   `-- manifest.json
|   |   |       |   |   |-- windows
|   |   |       |   |   |   |-- flutter
|   |   |       |   |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |   |-- generated_plugin_registrant.cc
|   |   |       |   |   |   |   |-- generated_plugin_registrant.h
|   |   |       |   |   |   |   `-- generated_plugins.cmake
|   |   |       |   |   |   |-- runner
|   |   |       |   |   |   |   |-- resources
|   |   |       |   |   |   |   |   `-- app_icon.ico
|   |   |       |   |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |   |-- flutter_window.cpp
|   |   |       |   |   |   |   |-- flutter_window.h
|   |   |       |   |   |   |   |-- main.cpp
|   |   |       |   |   |   |   |-- resource.h
|   |   |       |   |   |   |   |-- runner.exe.manifest
|   |   |       |   |   |   |   |-- Runner.rc
|   |   |       |   |   |   |   |-- utils.cpp
|   |   |       |   |   |   |   |-- utils.h
|   |   |       |   |   |   |   |-- win32_window.cpp
|   |   |       |   |   |   |   `-- win32_window.h
|   |   |       |   |   |   `-- CMakeLists.txt
|   |   |       |   |   |-- analysis_options.yaml
|   |   |       |   |   |-- pubspec.yaml
|   |   |       |   |   `-- README.md
|   |   |       |   |-- ios
|   |   |       |   |   |-- Classes
|   |   |       |   |   |   |-- AppLinksPlugin.h
|   |   |       |   |   |   |-- AppLinksPlugin.m
|   |   |       |   |   |   `-- SwiftAppLinksPlugin.swift
|   |   |       |   |   |-- Resources
|   |   |       |   |   |   `-- PrivacyInfo.xcprivacy
|   |   |       |   |   `-- app_links.podspec
|   |   |       |   |-- lib
|   |   |       |   |   |-- src
|   |   |       |   |   |   `-- app_links.dart
|   |   |       |   |   `-- app_links.dart
|   |   |       |   |-- macos
|   |   |       |   |   |-- Classes
|   |   |       |   |   |   `-- AppLinksMacosPlugin.swift
|   |   |       |   |   |-- Resources
|   |   |       |   |   |   `-- PrivacyInfo.xcprivacy
|   |   |       |   |   `-- app_links.podspec
|   |   |       |   |-- windows
|   |   |       |   |   |-- include
|   |   |       |   |   |   `-- app_links
|   |   |       |   |   |       `-- app_links_plugin_c_api.h
|   |   |       |   |   |-- app_links_plugin.cpp
|   |   |       |   |   |-- app_links_plugin.h
|   |   |       |   |   |-- app_links_plugin_c_api.cpp
|   |   |       |   |   `-- CMakeLists.txt
|   |   |       |   |-- analysis_options.yaml
|   |   |       |   |-- CHANGELOG.md
|   |   |       |   |-- LICENSE
|   |   |       |   |-- pubspec.yaml
|   |   |       |   `-- README.md
|   |   |       |-- file_selector_windows
|   |   |       |   |-- example
|   |   |       |   |   |-- lib
|   |   |       |   |   |   |-- get_directory_page.dart
|   |   |       |   |   |   |-- get_multiple_directories_page.dart
|   |   |       |   |   |   |-- home_page.dart
|   |   |       |   |   |   |-- main.dart
|   |   |       |   |   |   |-- open_image_page.dart
|   |   |       |   |   |   |-- open_multiple_images_page.dart
|   |   |       |   |   |   |-- open_text_page.dart
|   |   |       |   |   |   `-- save_text_page.dart
|   |   |       |   |   |-- windows
|   |   |       |   |   |   |-- flutter
|   |   |       |   |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |   `-- generated_plugins.cmake
|   |   |       |   |   |   |-- runner
|   |   |       |   |   |   |   |-- resources
|   |   |       |   |   |   |   |   `-- app_icon.ico
|   |   |       |   |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |   |-- flutter_window.cpp
|   |   |       |   |   |   |   |-- flutter_window.h
|   |   |       |   |   |   |   |-- main.cpp
|   |   |       |   |   |   |   |-- resource.h
|   |   |       |   |   |   |   |-- runner.exe.manifest
|   |   |       |   |   |   |   |-- Runner.rc
|   |   |       |   |   |   |   |-- utils.cpp
|   |   |       |   |   |   |   |-- utils.h
|   |   |       |   |   |   |   |-- win32_window.cpp
|   |   |       |   |   |   |   `-- win32_window.h
|   |   |       |   |   |   `-- CMakeLists.txt
|   |   |       |   |   |-- pubspec.yaml
|   |   |       |   |   `-- README.md
|   |   |       |   |-- lib
|   |   |       |   |   |-- src
|   |   |       |   |   |   `-- messages.g.dart
|   |   |       |   |   `-- file_selector_windows.dart
|   |   |       |   |-- pigeons
|   |   |       |   |   |-- copyright.txt
|   |   |       |   |   `-- messages.dart
|   |   |       |   |-- test
|   |   |       |   |   |-- file_selector_windows_test.dart
|   |   |       |   |   |-- file_selector_windows_test.mocks.dart
|   |   |       |   |   `-- test_api.g.dart
|   |   |       |   |-- windows
|   |   |       |   |   |-- include
|   |   |       |   |   |   `-- file_selector_windows
|   |   |       |   |   |       `-- file_selector_windows.h
|   |   |       |   |   |-- test
|   |   |       |   |   |   |-- file_selector_plugin_test.cpp
|   |   |       |   |   |   |-- test_file_dialog_controller.cpp
|   |   |       |   |   |   |-- test_file_dialog_controller.h
|   |   |       |   |   |   |-- test_main.cpp
|   |   |       |   |   |   |-- test_utils.cpp
|   |   |       |   |   |   `-- test_utils.h
|   |   |       |   |   |-- CMakeLists.txt
|   |   |       |   |   |-- file_dialog_controller.cpp
|   |   |       |   |   |-- file_dialog_controller.h
|   |   |       |   |   |-- file_selector_plugin.cpp
|   |   |       |   |   |-- file_selector_plugin.h
|   |   |       |   |   |-- file_selector_windows.cpp
|   |   |       |   |   |-- messages.g.cpp
|   |   |       |   |   |-- messages.g.h
|   |   |       |   |   |-- string_utils.cpp
|   |   |       |   |   `-- string_utils.h
|   |   |       |   |-- AUTHORS
|   |   |       |   |-- CHANGELOG.md
|   |   |       |   |-- LICENSE
|   |   |       |   |-- pubspec.yaml
|   |   |       |   `-- README.md
|   |   |       |-- firebase_core
|   |   |       |   |-- android
|   |   |       |   |   |-- gradle
|   |   |       |   |   |   `-- wrapper
|   |   |       |   |   |       `-- gradle-wrapper.properties
|   |   |       |   |   |-- src
|   |   |       |   |   |   `-- main
|   |   |       |   |   |       |-- java
|   |   |       |   |   |       |   `-- io
|   |   |       |   |   |       |       `-- flutter
|   |   |       |   |   |       |           `-- plugins
|   |   |       |   |   |       |               `-- firebase
|   |   |       |   |   |       |                   `-- core
|   |   |       |   |   |       |                       |-- FlutterFirebaseCorePlugin.java
|   |   |       |   |   |       |                       |-- FlutterFirebaseCoreRegistrar.java
|   |   |       |   |   |       |                       |-- FlutterFirebasePlugin.java
|   |   |       |   |   |       |                       |-- FlutterFirebasePluginRegistry.java
|   |   |       |   |   |       |                       `-- GeneratedAndroidFirebaseCore.java
|   |   |       |   |   |       `-- AndroidManifest.xml
|   |   |       |   |   |-- build.gradle
|   |   |       |   |   |-- gradle.properties
|   |   |       |   |   |-- settings.gradle
|   |   |       |   |   `-- user-agent.gradle
|   |   |       |   |-- example
|   |   |       |   |   |-- android
|   |   |       |   |   |   |-- app
|   |   |       |   |   |   |   |-- src
|   |   |       |   |   |   |   |   |-- debug
|   |   |       |   |   |   |   |   |   `-- AndroidManifest.xml
|   |   |       |   |   |   |   |   |-- main
|   |   |       |   |   |   |   |   |   |-- res
|   |   |       |   |   |   |   |   |   |   |-- drawable
|   |   |       |   |   |   |   |   |   |   |   `-- launch_background.xml
|   |   |       |   |   |   |   |   |   |   |-- mipmap-hdpi
|   |   |       |   |   |   |   |   |   |   |   `-- ic_launcher.png
|   |   |       |   |   |   |   |   |   |   |-- mipmap-mdpi
|   |   |       |   |   |   |   |   |   |   |   `-- ic_launcher.png
|   |   |       |   |   |   |   |   |   |   |-- mipmap-xhdpi
|   |   |       |   |   |   |   |   |   |   |   `-- ic_launcher.png
|   |   |       |   |   |   |   |   |   |   |-- mipmap-xxhdpi
|   |   |       |   |   |   |   |   |   |   |   `-- ic_launcher.png
|   |   |       |   |   |   |   |   |   |   |-- mipmap-xxxhdpi
|   |   |       |   |   |   |   |   |   |   |   `-- ic_launcher.png
|   |   |       |   |   |   |   |   |   |   `-- values
|   |   |       |   |   |   |   |   |   |       |-- styles.xml
|   |   |       |   |   |   |   |   |   |       `-- values.xml
|   |   |       |   |   |   |   |   |   `-- AndroidManifest.xml
|   |   |       |   |   |   |   |   `-- profile
|   |   |       |   |   |   |   |       `-- AndroidManifest.xml
|   |   |       |   |   |   |   `-- build.gradle
|   |   |       |   |   |   |-- gradle
|   |   |       |   |   |   |   `-- wrapper
|   |   |       |   |   |   |       `-- gradle-wrapper.properties
|   |   |       |   |   |   |-- build.gradle
|   |   |       |   |   |   |-- gradle.properties
|   |   |       |   |   |   `-- settings.gradle
|   |   |       |   |   |-- ios
|   |   |       |   |   |   |-- Flutter
|   |   |       |   |   |   |   |-- AppFrameworkInfo.plist
|   |   |       |   |   |   |   |-- Debug.xcconfig
|   |   |       |   |   |   |   `-- Release.xcconfig
|   |   |       |   |   |   |-- Runner
|   |   |       |   |   |   |   |-- Assets.xcassets
|   |   |       |   |   |   |   |   |-- AppIcon.appiconset
|   |   |       |   |   |   |   |   |   |-- Contents.json
|   |   |       |   |   |   |   |   |   |-- Icon-App-1024x1024@1x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-20x20@1x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-20x20@2x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-20x20@3x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-29x29@1x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-29x29@2x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-29x29@3x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-40x40@1x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-40x40@2x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-40x40@3x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-60x60@2x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-60x60@3x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-76x76@1x.png
|   |   |       |   |   |   |   |   |   |-- Icon-App-76x76@2x.png
|   |   |       |   |   |   |   |   |   `-- Icon-App-83.5x83.5@2x.png
|   |   |       |   |   |   |   |   `-- LaunchImage.imageset
|   |   |       |   |   |   |   |       |-- Contents.json
|   |   |       |   |   |   |   |       |-- LaunchImage.png
|   |   |       |   |   |   |   |       |-- LaunchImage@2x.png
|   |   |       |   |   |   |   |       |-- LaunchImage@3x.png
|   |   |       |   |   |   |   |       `-- README.md
|   |   |       |   |   |   |   |-- Base.lproj
|   |   |       |   |   |   |   |   |-- LaunchScreen.storyboard
|   |   |       |   |   |   |   |   `-- Main.storyboard
|   |   |       |   |   |   |   |-- AppDelegate.h
|   |   |       |   |   |   |   |-- AppDelegate.m
|   |   |       |   |   |   |   |-- Info.plist
|   |   |       |   |   |   |   `-- main.m
|   |   |       |   |   |   |-- Runner.xcodeproj
|   |   |       |   |   |   |   |-- project.xcworkspace
|   |   |       |   |   |   |   |   `-- contents.xcworkspacedata
|   |   |       |   |   |   |   |-- xcshareddata
|   |   |       |   |   |   |   |   `-- xcschemes
|   |   |       |   |   |   |   |       `-- Runner.xcscheme
|   |   |       |   |   |   |   `-- project.pbxproj
|   |   |       |   |   |   |-- Runner.xcworkspace
|   |   |       |   |   |   |   |-- xcshareddata
|   |   |       |   |   |   |   |   `-- IDEWorkspaceChecks.plist
|   |   |       |   |   |   |   `-- contents.xcworkspacedata
|   |   |       |   |   |   `-- Podfile
|   |   |       |   |   |-- lib
|   |   |       |   |   |   |-- firebase_options.dart
|   |   |       |   |   |   `-- main.dart
|   |   |       |   |   |-- macos
|   |   |       |   |   |   |-- Flutter
|   |   |       |   |   |   |   |-- Flutter-Debug.xcconfig
|   |   |       |   |   |   |   `-- Flutter-Release.xcconfig
|   |   |       |   |   |   |-- Runner
|   |   |       |   |   |   |   |-- Assets.xcassets
|   |   |       |   |   |   |   |   `-- AppIcon.appiconset
|   |   |       |   |   |   |   |       |-- app_icon_1024.png
|   |   |       |   |   |   |   |       |-- app_icon_128.png
|   |   |       |   |   |   |   |       |-- app_icon_16.png
|   |   |       |   |   |   |   |       |-- app_icon_256.png
|   |   |       |   |   |   |   |       |-- app_icon_32.png
|   |   |       |   |   |   |   |       |-- app_icon_512.png
|   |   |       |   |   |   |   |       |-- app_icon_64.png
|   |   |       |   |   |   |   |       `-- Contents.json
|   |   |       |   |   |   |   |-- Base.lproj
|   |   |       |   |   |   |   |   `-- MainMenu.xib
|   |   |       |   |   |   |   |-- Configs
|   |   |       |   |   |   |   |   |-- AppInfo.xcconfig
|   |   |       |   |   |   |   |   |-- Debug.xcconfig
|   |   |       |   |   |   |   |   |-- Release.xcconfig
|   |   |       |   |   |   |   |   `-- Warnings.xcconfig
|   |   |       |   |   |   |   |-- AppDelegate.swift
|   |   |       |   |   |   |   |-- DebugProfile.entitlements
|   |   |       |   |   |   |   |-- Info.plist
|   |   |       |   |   |   |   |-- MainFlutterWindow.swift
|   |   |       |   |   |   |   `-- Release.entitlements
|   |   |       |   |   |   |-- Runner.xcodeproj
|   |   |       |   |   |   |   |-- project.xcworkspace
|   |   |       |   |   |   |   |   |-- xcshareddata
|   |   |       |   |   |   |   |   |   `-- IDEWorkspaceChecks.plist
|   |   |       |   |   |   |   |   `-- contents.xcworkspacedata
|   |   |       |   |   |   |   |-- xcshareddata
|   |   |       |   |   |   |   |   `-- xcschemes
|   |   |       |   |   |   |   |       `-- Runner.xcscheme
|   |   |       |   |   |   |   `-- project.pbxproj
|   |   |       |   |   |   |-- Runner.xcworkspace
|   |   |       |   |   |   |   |-- xcshareddata
|   |   |       |   |   |   |   |   |-- IDEWorkspaceChecks.plist
|   |   |       |   |   |   |   |   `-- WorkspaceSettings.xcsettings
|   |   |       |   |   |   |   `-- contents.xcworkspacedata
|   |   |       |   |   |   `-- Podfile
|   |   |       |   |   |-- web
|   |   |       |   |   |   `-- index.html
|   |   |       |   |   |-- windows
|   |   |       |   |   |   |-- flutter
|   |   |       |   |   |   |   `-- CMakeLists.txt
|   |   |       |   |   |   |-- runner
|   |   |       |   |   |   |   |-- resources
|   |   |       |   |   |   |   |   `-- app_icon.ico
|   |   |       |   |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |   |-- flutter_window.cpp
|   |   |       |   |   |   |   |-- flutter_window.h
|   |   |       |   |   |   |   |-- main.cpp
|   |   |       |   |   |   |   |-- resource.h
|   |   |       |   |   |   |   |-- runner.exe.manifest
|   |   |       |   |   |   |   |-- Runner.rc
|   |   |       |   |   |   |   |-- utils.cpp
|   |   |       |   |   |   |   |-- utils.h
|   |   |       |   |   |   |   |-- win32_window.cpp
|   |   |       |   |   |   |   `-- win32_window.h
|   |   |       |   |   |   `-- CMakeLists.txt
|   |   |       |   |   |-- analysis_options.yaml
|   |   |       |   |   |-- pubspec.yaml
|   |   |       |   |   `-- README.md
|   |   |       |   |-- ios
|   |   |       |   |   |-- Classes
|   |   |       |   |   |   |-- FLTFirebaseCorePlugin.h
|   |   |       |   |   |   |-- FLTFirebaseCorePlugin.m
|   |   |       |   |   |   |-- FLTFirebasePlugin.h
|   |   |       |   |   |   |-- FLTFirebasePlugin.m
|   |   |       |   |   |   |-- FLTFirebasePluginRegistry.h
|   |   |       |   |   |   |-- FLTFirebasePluginRegistry.m
|   |   |       |   |   |   |-- messages.g.h
|   |   |       |   |   |   `-- messages.g.m
|   |   |       |   |   |-- firebase_core.podspec
|   |   |       |   |   `-- firebase_sdk_version.rb
|   |   |       |   |-- lib
|   |   |       |   |   |-- src
|   |   |       |   |   |   |-- firebase.dart
|   |   |       |   |   |   `-- firebase_app.dart
|   |   |       |   |   `-- firebase_core.dart
|   |   |       |   |-- macos
|   |   |       |   |   |-- Classes
|   |   |       |   |   |   |-- FLTFirebaseCorePlugin.h
|   |   |       |   |   |   |-- FLTFirebaseCorePlugin.m
|   |   |       |   |   |   |-- FLTFirebasePlugin.h
|   |   |       |   |   |   |-- FLTFirebasePlugin.m
|   |   |       |   |   |   |-- FLTFirebasePluginRegistry.h
|   |   |       |   |   |   |-- FLTFirebasePluginRegistry.m
|   |   |       |   |   |   |-- messages.g.h
|   |   |       |   |   |   `-- messages.g.m
|   |   |       |   |   `-- firebase_core.podspec
|   |   |       |   |-- test
|   |   |       |   |   `-- firebase_core_test.dart
|   |   |       |   |-- windows
|   |   |       |   |   |-- include
|   |   |       |   |   |   `-- firebase_core
|   |   |       |   |   |       `-- firebase_core_plugin_c_api.h
|   |   |       |   |   |-- CMakeLists.txt
|   |   |       |   |   |-- firebase_core_plugin.cpp
|   |   |       |   |   |-- firebase_core_plugin.h
|   |   |       |   |   |-- firebase_core_plugin_c_api.cpp
|   |   |       |   |   |-- messages.g.cpp
|   |   |       |   |   |-- messages.g.h
|   |   |       |   |   `-- plugin_version.h.in
|   |   |       |   |-- CHANGELOG.md
|   |   |       |   |-- LICENSE
|   |   |       |   |-- pubspec.yaml
|   |   |       |   `-- README.md
|   |   |       |-- image_picker_windows
|   |   |       |   |-- example
|   |   |       |   |   |-- lib
|   |   |       |   |   |   `-- main.dart
|   |   |       |   |   |-- windows
|   |   |       |   |   |   |-- flutter
|   |   |       |   |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |   `-- generated_plugins.cmake
|   |   |       |   |   |   |-- runner
|   |   |       |   |   |   |   |-- resources
|   |   |       |   |   |   |   |   `-- app_icon.ico
|   |   |       |   |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |   |-- flutter_window.cpp
|   |   |       |   |   |   |   |-- flutter_window.h
|   |   |       |   |   |   |   |-- main.cpp
|   |   |       |   |   |   |   |-- resource.h
|   |   |       |   |   |   |   |-- runner.exe.manifest
|   |   |       |   |   |   |   |-- Runner.rc
|   |   |       |   |   |   |   |-- utils.cpp
|   |   |       |   |   |   |   |-- utils.h
|   |   |       |   |   |   |   |-- win32_window.cpp
|   |   |       |   |   |   |   `-- win32_window.h
|   |   |       |   |   |   `-- CMakeLists.txt
|   |   |       |   |   |-- pubspec.yaml
|   |   |       |   |   `-- README.md
|   |   |       |   |-- lib
|   |   |       |   |   `-- image_picker_windows.dart
|   |   |       |   |-- test
|   |   |       |   |   |-- image_picker_windows_test.dart
|   |   |       |   |   `-- image_picker_windows_test.mocks.dart
|   |   |       |   |-- AUTHORS
|   |   |       |   |-- CHANGELOG.md
|   |   |       |   |-- LICENSE
|   |   |       |   |-- pubspec.yaml
|   |   |       |   `-- README.md
|   |   |       |-- path_provider_windows
|   |   |       |   |-- example
|   |   |       |   |   |-- integration_test
|   |   |       |   |   |   `-- path_provider_test.dart
|   |   |       |   |   |-- lib
|   |   |       |   |   |   `-- main.dart
|   |   |       |   |   |-- test_driver
|   |   |       |   |   |   `-- integration_test.dart
|   |   |       |   |   |-- windows
|   |   |       |   |   |   |-- flutter
|   |   |       |   |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |   `-- generated_plugins.cmake
|   |   |       |   |   |   |-- runner
|   |   |       |   |   |   |   |-- resources
|   |   |       |   |   |   |   |   `-- app_icon.ico
|   |   |       |   |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |   |-- flutter_window.cpp
|   |   |       |   |   |   |   |-- flutter_window.h
|   |   |       |   |   |   |   |-- main.cpp
|   |   |       |   |   |   |   |-- resource.h
|   |   |       |   |   |   |   |-- run_loop.cpp
|   |   |       |   |   |   |   |-- run_loop.h
|   |   |       |   |   |   |   |-- runner.exe.manifest
|   |   |       |   |   |   |   |-- Runner.rc
|   |   |       |   |   |   |   |-- utils.cpp
|   |   |       |   |   |   |   |-- utils.h
|   |   |       |   |   |   |   |-- win32_window.cpp
|   |   |       |   |   |   |   `-- win32_window.h
|   |   |       |   |   |   `-- CMakeLists.txt
|   |   |       |   |   |-- pubspec.yaml
|   |   |       |   |   `-- README.md
|   |   |       |   |-- lib
|   |   |       |   |   |-- src
|   |   |       |   |   |   |-- folders.dart
|   |   |       |   |   |   |-- folders_stub.dart
|   |   |       |   |   |   |-- guid.dart
|   |   |       |   |   |   |-- path_provider_windows_real.dart
|   |   |       |   |   |   |-- path_provider_windows_stub.dart
|   |   |       |   |   |   `-- win32_wrappers.dart
|   |   |       |   |   `-- path_provider_windows.dart
|   |   |       |   |-- test
|   |   |       |   |   |-- guid_test.dart
|   |   |       |   |   `-- path_provider_windows_test.dart
|   |   |       |   |-- AUTHORS
|   |   |       |   |-- CHANGELOG.md
|   |   |       |   |-- LICENSE
|   |   |       |   |-- pubspec.yaml
|   |   |       |   `-- README.md
|   |   |       |-- shared_preferences_windows
|   |   |       |   |-- example
|   |   |       |   |   |-- integration_test
|   |   |       |   |   |   `-- shared_preferences_test.dart
|   |   |       |   |   |-- lib
|   |   |       |   |   |   `-- main.dart
|   |   |       |   |   |-- test_driver
|   |   |       |   |   |   `-- integration_test.dart
|   |   |       |   |   |-- windows
|   |   |       |   |   |   |-- flutter
|   |   |       |   |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |   `-- generated_plugins.cmake
|   |   |       |   |   |   |-- runner
|   |   |       |   |   |   |   |-- resources
|   |   |       |   |   |   |   |   `-- app_icon.ico
|   |   |       |   |   |   |   |-- CMakeLists.txt
|   |   |       |   |   |   |   |-- flutter_window.cpp
|   |   |       |   |   |   |   |-- flutter_window.h
|   |   |       |   |   |   |   |-- main.cpp
|   |   |       |   |   |   |   |-- resource.h
|   |   |       |   |   |   |   |-- run_loop.cpp
|   |   |       |   |   |   |   |-- run_loop.h
|   |   |       |   |   |   |   |-- runner.exe.manifest
|   |   |       |   |   |   |   |-- Runner.rc
|   |   |       |   |   |   |   |-- utils.cpp
|   |   |       |   |   |   |   |-- utils.h
|   |   |       |   |   |   |   |-- win32_window.cpp
|   |   |       |   |   |   |   `-- win32_window.h
|   |   |       |   |   |   `-- CMakeLists.txt
|   |   |       |   |   |-- AUTHORS
|   |   |       |   |   |-- LICENSE
|   |   |       |   |   |-- pubspec.yaml
|   |   |       |   |   `-- README.md
|   |   |       |   |-- lib
|   |   |       |   |   `-- shared_preferences_windows.dart
|   |   |       |   |-- test
|   |   |       |   |   |-- fake_path_provider_windows.dart
|   |   |       |   |   |-- legacy_shared_preferences_windows_test.dart
|   |   |       |   |   `-- shared_preferences_windows_async_test.dart
|   |   |       |   |-- AUTHORS
|   |   |       |   |-- CHANGELOG.md
|   |   |       |   |-- LICENSE
|   |   |       |   |-- pubspec.yaml
|   |   |       |   `-- README.md
|   |   |       `-- url_launcher_windows
|   |   |           |-- example
|   |   |           |   |-- integration_test
|   |   |           |   |   `-- url_launcher_test.dart
|   |   |           |   |-- lib
|   |   |           |   |   `-- main.dart
|   |   |           |   |-- test_driver
|   |   |           |   |   `-- integration_test.dart
|   |   |           |   |-- windows
|   |   |           |   |   |-- flutter
|   |   |           |   |   |   |-- CMakeLists.txt
|   |   |           |   |   |   `-- generated_plugins.cmake
|   |   |           |   |   |-- runner
|   |   |           |   |   |   |-- resources
|   |   |           |   |   |   |   `-- app_icon.ico
|   |   |           |   |   |   |-- CMakeLists.txt
|   |   |           |   |   |   |-- flutter_window.cpp
|   |   |           |   |   |   |-- flutter_window.h
|   |   |           |   |   |   |-- main.cpp
|   |   |           |   |   |   |-- resource.h
|   |   |           |   |   |   |-- run_loop.cpp
|   |   |           |   |   |   |-- run_loop.h
|   |   |           |   |   |   |-- runner.exe.manifest
|   |   |           |   |   |   |-- Runner.rc
|   |   |           |   |   |   |-- utils.cpp
|   |   |           |   |   |   |-- utils.h
|   |   |           |   |   |   |-- win32_window.cpp
|   |   |           |   |   |   `-- win32_window.h
|   |   |           |   |   `-- CMakeLists.txt
|   |   |           |   |-- pubspec.yaml
|   |   |           |   `-- README.md
|   |   |           |-- lib
|   |   |           |   |-- src
|   |   |           |   |   `-- messages.g.dart
|   |   |           |   `-- url_launcher_windows.dart
|   |   |           |-- pigeons
|   |   |           |   |-- copyright.txt
|   |   |           |   `-- messages.dart
|   |   |           |-- test
|   |   |           |   `-- url_launcher_windows_test.dart
|   |   |           |-- windows
|   |   |           |   |-- include
|   |   |           |   |   `-- url_launcher_windows
|   |   |           |   |       `-- url_launcher_windows.h
|   |   |           |   |-- test
|   |   |           |   |   `-- url_launcher_windows_test.cpp
|   |   |           |   |-- CMakeLists.txt
|   |   |           |   |-- messages.g.cpp
|   |   |           |   |-- messages.g.h
|   |   |           |   |-- system_apis.cpp
|   |   |           |   |-- system_apis.h
|   |   |           |   |-- url_launcher_plugin.cpp
|   |   |           |   |-- url_launcher_plugin.h
|   |   |           |   `-- url_launcher_windows.cpp
|   |   |           |-- AUTHORS
|   |   |           |-- CHANGELOG.md
|   |   |           |-- LICENSE
|   |   |           |-- pubspec.yaml
|   |   |           `-- README.md
|   |   |-- CMakeLists.txt
|   |   |-- generated_plugin_registrant.cc
|   |   |-- generated_plugin_registrant.h
|   |   `-- generated_plugins.cmake
|   |-- runner
|   |   |-- resources
|   |   |   `-- app_icon.ico
|   |   |-- CMakeLists.txt
|   |   |-- flutter_window.cpp
|   |   |-- flutter_window.h
|   |   |-- main.cpp
|   |   |-- resource.h
|   |   |-- runner.exe.manifest
|   |   |-- Runner.rc
|   |   |-- utils.cpp
|   |   |-- utils.h
|   |   |-- win32_window.cpp
|   |   `-- win32_window.h
|   |-- .gitignore
|   `-- CMakeLists.txt
|-- .flutter-plugins
|-- .flutter-plugins-dependencies
|-- .gitignore
|-- .metadata
|-- AGENTS.md
|-- AI_STRUCTURE.md
|-- analysis_options.yaml
|-- devtools_options.yaml
|-- firebase.json
|-- prince_academy.iml
|-- pubspec.lock
|-- pubspec.yaml
|-- README.md
`-- README_AI.md
```

## Top-level overview

| Path | Role |
|------|------|
| `lib/` | Flutter application source (features, core, view) |
| `supabase/` | SQL schema and RPC source of truth |
| `docs/` | Human documentation |
| `ai/` | AI context packs, memory, workflows, standards |
| `agents/` | Agent role definitions |
| `examples/` | Code pattern excerpts |
| `.cursor/` | Cursor rules and skills |
| `android/`, `ios/`, `web/` | Platform shells |
| `assets/` | Images, fonts, static files |
| `test/` | Unit and widget tests |
