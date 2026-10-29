// Alternative QC using the pre-resized 1024x1024 BMP (no texture-resize directive).
// V10 reconstructed from original GLB; root-bone mesh assignments removed and 393 animation clips visually audited headless.
// Rigid one-bone-per-corner approximation remains; compilation/runtime have not been tested.
// Requires a compatible extended FunnkyHD StudioMDL implementation supporting $splitmesh 2048.
$modelname "models/player/yorha/yorha.mdl"
$cd "."
$cdtexture "./textures_windows_1024/"
$scale 1.0
$splitmesh 2048
$body "body" "mesh/custom_player_highpoly_windows"
$flags 0
$eyeposition 0.000000 0.000000 57.000000
$bbox -32.000 -9.000 -0.500 32.000 9.000 65.000
$cbox -32.000 -9.000 -0.500 32.000 9.000 65.000
$keepallbones

// Hitbox definitions inherited from the supplied Yorha player reference.
$hbox 0 "Bip01 Pelvis" -10.750357 -11.526649 -12.839758 7.352994 11.149719 12.873248
$hbox 0 "Bip01 Spine2" 0.000000 -2.919254 -3.647657 2.305373 3.164980 3.405282
$hbox 0 "Bip01 Spine3" -0.398287 -3.180830 -4.202164 11.795180 4.577267 4.002062
$hbox 0 "Bip01 L Arm1" -1.206255 -2.969728 -2.235342 8.915800 2.900025 3.236248
$hbox 0 "Bip01 L Arm2" 0.000000 -4.250087 -4.593582 8.645243 4.273333 3.577995
$hbox 0 "Bip01 L Hand" -0.106558 -0.516103 -2.211401 3.619231 1.448725 1.506635
$hbox 0 "l5" -0.162778 -0.691287 -1.118859 3.047616 0.920910 0.966374
$hbox 0 "Bip01 R Arm1" -1.739831 -2.940108 -2.957750 8.527894 2.825783 2.324480
$hbox 0 "Bip01 R Arm2" -0.883077 -4.071182 -3.728313 8.948360 4.485007 4.427007
$hbox 0 "Bip01 R Hand" -8.902394 -0.729286 -1.500272 3.647746 1.389795 2.130233
$hbox 0 "Bip01 Head" -1.012119 -5.156627 -4.139709 7.901833 3.948009 4.126658
$hbox 0 "Bip01 L Leg" 0.000000 -2.580606 -2.723005 14.042620 3.738307 3.481366
$hbox 0 "Bip01 R Leg" 0.000000 -2.597862 -2.889464 14.054862 3.721249 3.245187
$hbox 0 "Bip01 L Leg upb" 0.000000 -2.857775 -2.459522 1.489942 1.038175 3.487627
$hbox 0 "Bip01 R Leg upb" 0.000000 -2.875234 -2.896778 1.509904 1.019808 3.050464
$hbox 0 "Bip01 R Leg upb.001" 0.000000 -3.284697 -2.926123 1.061844 1.011234 2.952894
$hbox 0 "Bip01 R Leg upb.003" -0.541594 -3.780964 -3.156766 0.550441 0.875581 2.690332
$hbox 0 "Bip01 R Leg upb.004" -1.148662 -3.911554 -2.827296 0.000000 0.000000 2.549265
$hbox 0 "Bip01 R Leg upf" 0.000000 0.000000 -2.673019 2.047944 3.725081 3.343881
$hbox 0 "Bip01 R Leg upf.001" 0.000000 0.000000 -2.659144 1.531567 3.704729 3.343890
$hbox 0 "Bip01 R Leg upf.002" 0.000000 0.000000 -2.676501 1.062904 3.635437 3.255633
$hbox 0 "Bip01 R Leg upf.005" -1.158637 0.000000 -2.251758 0.038635 3.450783 2.878897
$hbox 0 "Bip01 R Leg upf.006" -1.815636 0.000000 -2.141626 0.000000 3.404488 2.694638
$hbox 0 "Bip01 L Leg upb.001" 0.000000 -3.266963 -2.362986 1.040721 1.029652 3.516351
$hbox 0 "Bip01 L Leg upb.003" -0.553942 -3.763063 -2.102865 0.526318 0.893964 3.746782
$hbox 0 "Bip01 L Leg upb.004" -1.161296 -3.893720 -1.963033 0.000000 0.000000 3.415905
$hbox 0 "Bip01 L Leg upf" 0.000000 0.000000 -2.751911 2.019031 3.742195 3.264919
$hbox 0 "Bip01 L Leg upf.001" 0.000000 0.000000 -2.753283 1.508479 3.721865 3.250003
$hbox 0 "Bip01 L Leg upf.002" 0.000000 0.000000 -2.666313 1.039778 3.652601 3.266412
$hbox 0 "Bip01 L Leg upf.005" -1.170793 0.000000 -2.293234 0.016376 3.468045 2.839431
$hbox 0 "Bip01 L Leg upf.006" -1.828143 0.000000 -2.110252 0.000000 3.421781 2.728973
$hbox 0 "Bip01 L Leg1" 0.000000 -2.150023 -2.953821 13.652570 2.939966 1.268812
$hbox 0 "Bip01 L Foot" -0.362712 -1.788413 -1.230834 6.684509 6.785208 1.766648
$hbox 0 "Bip01 R Leg1" 0.000000 -2.149040 -1.255010 13.650827 2.940870 2.967821
$hbox 0 "Bip01 R Foot" -0.358674 -1.789797 -1.693867 6.688732 6.783602 1.303551

// Original bone controllers preserved.
$controller 0 "Bip01 Spine" XR -30.000000 30.000000
$controller 1 "Bip01 Spine1" XR -30.000000 30.000000
$controller 2 "Bip01 Spine2" XR -30.000000 30.000000
$controller 3 "Bip01 Spine3" XR -30.000000 30.000000
$controller Mouth "Bip01 Head" ZR 0.000000 15.000000

// Original sequence names/order/FPS/blend definitions preserved.
$sequence "By_Shinsen" {
	"anims/By_Shinsen_blend01"
	"anims/By_Shinsen_blend02"
	ACT_1 2
	blend XR -90 90
	fps 14
	loop
}
$sequence "idle" {
	"anims/idle_blend01"
	"anims/idle_blend02"
	ACT_1 1
	blend XR -90 90
	fps 14
	loop
}
$sequence "deep_idle" {
	"anims/deep_idle_blend01"
	"anims/deep_idle_blend02"
	ACT_1 4
	blend XR -90 90
	fps 14
	loop
}
$sequence "run2" {
	"anims/run2_blend01"
	"anims/run2_blend02"
	ACT_4 1
	blend XR -90 90
	fps 40
	loop
	 LX
}
$sequence "walk" {
	"anims/walk_blend01"
	"anims/walk_blend02"
	ACT_3 1
	blend XR -90 90
	fps 20
	loop
	 LX
}
$sequence "2handshoot" {
	"anims/2handshoot_blend01"
	"anims/2handshoot_blend02"
	ACT_28 1
	blend XR -90 90
	fps 20
}
$sequence "crawl" {
	"anims/crawl_blend01"
	"anims/crawl_blend02"
	ACT_17 1
	blend XR -90 90
	fps 22
	loop
	 LX
}
$sequence "crouch_idle" {
	"anims/crouch_idle_blend01"
	"anims/crouch_idle_blend02"
	ACT_18 1
	blend XR -90 90
	fps 12
	loop
}
$sequence "jump" {
	"anims/jump_blend01"
	"anims/jump_blend02"
	ACT_7 1
	blend XR -90 90
	fps 30
}
$sequence "long_jump" {
	"anims/long_jump"
	ACT_8 1
	fps 24
	 LX
}
$sequence "swim" {
	"anims/swim"
	ACT_6 1
	fps 14
	loop
}
$sequence "treadwater" {
	"anims/treadwater"
	ACT_50 1
	fps 10
	loop
}
$sequence "die_simple" {
	"anims/die_simple_blend01"
	"anims/die_simple_blend02"
	ACT_36 1
	blend XR -90 90
	{ event 2001 10 }
	fps 16
}
$sequence "die_backwards1" {
	"anims/die_backwards1_blend01"
	"anims/die_backwards1_blend02"
	ACT_37 4
	blend XR -90 90
	{ event 2001 14 }
	fps 17
}
$sequence "die_backwards" {
	"anims/die_backwards_blend01"
	"anims/die_backwards_blend02"
	ACT_37 1
	blend XR -90 90
	{ event 2001 15 }
	fps 26
}
$sequence "die_forwards" {
	"anims/die_forwards_blend01"
	"anims/die_forwards_blend02"
	ACT_38 1
	blend XR -90 90
	{ event 2001 9 }
	fps 18
}
$sequence "headshot" {
	"anims/headshot_blend01"
	"anims/headshot_blend02"
	ACT_66 4
	blend XR -90 90
	{ event 2001 23 }
	fps 20
}
$sequence "die_spin" {
	"anims/die_spin_blend01"
	"anims/die_spin_blend02"
	ACT_66 1
	blend XR -90 90
	{ event 2001 16 }
	fps 25
}
$sequence "gutshot" {
	"anims/gutshot_blend01"
	"anims/gutshot_blend02"
	ACT_68 1
	blend XR -90 90
	{ event 2001 15 }
	fps 18
}
$sequence "ref_draw_crowbar" {
	"anims/ref_draw_crowbar_blend01"
	"anims/ref_draw_crowbar_blend02"
	blend XR -90 90
	fps 12
}
$sequence "ref_aim_crowbar" {
	"anims/ref_aim_crowbar_blend01"
	"anims/ref_aim_crowbar_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "ref_shoot_crowbar" {
	"anims/ref_shoot_crowbar_blend01"
	"anims/ref_shoot_crowbar_blend02"
	blend XR -90 90
	fps 24
}
$sequence "crouch_draw_crowbar" {
	"anims/crouch_draw_crowbar_blend01"
	"anims/crouch_draw_crowbar_blend02"
	blend XR -90 90
	fps 12
}
$sequence "crouch_aim_crowbar" {
	"anims/crouch_aim_crowbar_blend01"
	"anims/crouch_aim_crowbar_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "crouch_shoot_crowbar" {
	"anims/crouch_shoot_crowbar_blend01"
	"anims/crouch_shoot_crowbar_blend02"
	blend XR -90 90
	fps 24
}
$sequence "ref_cock_wrench" {
	"anims/ref_cock_wrench_blend01"
	"anims/ref_cock_wrench_blend02"
	blend XR -90 90
	fps 7
}
$sequence "ref_hold_wrench" {
	"anims/ref_hold_wrench_blend01"
	"anims/ref_hold_wrench_blend02"
	blend XR -90 90
	fps 13
}
$sequence "ref_shoot_wrench" {
	"anims/ref_shoot_wrench_blend01"
	"anims/ref_shoot_wrench_blend02"
	blend XR -90 90
	fps 30
}
$sequence "crouch_cock_wrench" {
	"anims/crouch_cock_wrench_blend01"
	"anims/crouch_cock_wrench_blend02"
	blend XR -90 90
	fps 7
}
$sequence "crouch_hold_wrench" {
	"anims/crouch_hold_wrench_blend01"
	"anims/crouch_hold_wrench_blend02"
	blend XR -90 90
	fps 13
}
$sequence "crouch_shoot_wrench" {
	"anims/crouch_shoot_wrench_blend01"
	"anims/crouch_shoot_wrench_blend02"
	blend XR -90 90
	fps 30
}
$sequence "ref_draw_gren" {
	"anims/ref_draw_gren_blend01"
	"anims/ref_draw_gren_blend02"
	blend XR -90 90
	fps 10
}
$sequence "ref_aim_gren" {
	"anims/ref_aim_gren_blend01"
	"anims/ref_aim_gren_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "ref_cock_gren" {
	"anims/ref_cock_gren_blend01"
	"anims/ref_cock_gren_blend02"
	blend XR -90 90
	fps 18
}
$sequence "ref_hold_gren" {
	"anims/ref_hold_gren_blend01"
	"anims/ref_hold_gren_blend02"
	blend XR -90 90
	fps 15
	loop
}
$sequence "ref_shoot_gren" {
	"anims/ref_shoot_gren_blend01"
	"anims/ref_shoot_gren_blend02"
	blend XR -90 90
	fps 15
}
$sequence "crouch_draw_gren" {
	"anims/crouch_draw_gren_blend01"
	"anims/crouch_draw_gren_blend02"
	blend XR -90 90
	fps 12
}
$sequence "crouch_aim_gren" {
	"anims/crouch_aim_gren_blend01"
	"anims/crouch_aim_gren_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "crouch_cock_gren" {
	"anims/crouch_cock_gren_blend01"
	"anims/crouch_cock_gren_blend02"
	blend XR -90 90
	fps 12
}
$sequence "crouch_hold_gren" {
	"anims/crouch_hold_gren_blend01"
	"anims/crouch_hold_gren_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "crouch_shoot_gren" {
	"anims/crouch_shoot_gren_blend01"
	"anims/crouch_shoot_gren_blend02"
	blend XR -90 90
	fps 16
}
$sequence "ref_draw_trip" {
	"anims/ref_draw_trip_blend01"
	"anims/ref_draw_trip_blend02"
	blend XR -90 90
	fps 12
}
$sequence "ref_aim_trip" {
	"anims/ref_aim_trip_blend01"
	"anims/ref_aim_trip_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "ref_shoot_trip" {
	"anims/ref_shoot_trip_blend01"
	"anims/ref_shoot_trip_blend02"
	blend XR -90 90
	fps 18
}
$sequence "crouch_draw_trip" {
	"anims/crouch_draw_trip_blend01"
	"anims/crouch_draw_trip_blend02"
	blend XR -90 90
	fps 12
}
$sequence "crouch_aim_trip" {
	"anims/crouch_aim_trip_blend01"
	"anims/crouch_aim_trip_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "crouch_shoot_trip" {
	"anims/crouch_shoot_trip_blend01"
	"anims/crouch_shoot_trip_blend02"
	blend XR -90 90
	fps 16
}
$sequence "ref_draw_onehanded" {
	"anims/ref_draw_onehanded_blend01"
	"anims/ref_draw_onehanded_blend02"
	blend XR -90 90
	fps 12
}
$sequence "ref_aim_onehanded" {
	"anims/ref_aim_onehanded_blend01"
	"anims/ref_aim_onehanded_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "ref_shoot_onehanded" {
	"anims/ref_shoot_onehanded_blend01"
	"anims/ref_shoot_onehanded_blend02"
	blend XR -90 90
	{ event 5011 0 "21" }
	fps 16
}
$sequence "ref_reload_onehanded" {
	"anims/ref_reload_onehanded_blend01"
	"anims/ref_reload_onehanded_blend02"
	blend XR -90 90
	fps 20
}
$sequence "crouch_draw_onehanded" {
	"anims/crouch_draw_onehanded_blend01"
	"anims/crouch_draw_onehanded_blend02"
	blend XR -90 90
	fps 12
}
$sequence "crouch_aim_onehanded" {
	"anims/crouch_aim_onehanded_blend01"
	"anims/crouch_aim_onehanded_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "crouch_shoot_onehanded" {
	"anims/crouch_shoot_onehanded_blend01"
	"anims/crouch_shoot_onehanded_blend02"
	blend XR -90 90
	{ event 5011 0 "21" }
	fps 25
}
$sequence "crouch_reload_onehanded" {
	"anims/crouch_reload_onehanded_blend01"
	"anims/crouch_reload_onehanded_blend02"
	blend XR -90 90
	fps 20
}
$sequence "ref_draw_python" {
	"anims/ref_draw_python_blend01"
	"anims/ref_draw_python_blend02"
	blend XR -90 90
	fps 15
}
$sequence "ref_aim_python" {
	"anims/ref_aim_python_blend01"
	"anims/ref_aim_python_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "ref_shoot_python" {
	"anims/ref_shoot_python_blend01"
	"anims/ref_shoot_python_blend02"
	blend XR -90 90
	{ event 5011 0 "31" }
	fps 16
}
$sequence "ref_reload_python" {
	"anims/ref_reload_python_blend01"
	"anims/ref_reload_python_blend02"
	blend XR -90 90
	fps 15
}
$sequence "crouch_draw_python" {
	"anims/crouch_draw_python_blend01"
	"anims/crouch_draw_python_blend02"
	blend XR -90 90
	fps 15
}
$sequence "crouch_aim_python" {
	"anims/crouch_aim_python_blend01"
	"anims/crouch_aim_python_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "crouch_shoot_python" {
	"anims/crouch_shoot_python_blend01"
	"anims/crouch_shoot_python_blend02"
	blend XR -90 90
	{ event 5011 0 "31" }
	fps 16
}
$sequence "crouch_reload_python" {
	"anims/crouch_reload_python_blend01"
	"anims/crouch_reload_python_blend02"
	blend XR -90 90
	fps 15
}
$sequence "ref_draw_shotgun" {
	"anims/ref_draw_shotgun_blend01"
	"anims/ref_draw_shotgun_blend02"
	blend XR -90 90
	fps 18
}
$sequence "ref_aim_shotgun" {
	"anims/ref_aim_shotgun_blend01"
	"anims/ref_aim_shotgun_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "ref_shoot_shotgun" {
	"anims/ref_shoot_shotgun_blend01"
	"anims/ref_shoot_shotgun_blend02"
	blend XR -90 90
	{ event 5005 0 "muzzle_SG.txt" }
	fps 20
}
$sequence "ref_reload_shotgun" {
	"anims/ref_reload_shotgun_blend01"
	"anims/ref_reload_shotgun_blend02"
	blend XR -90 90
	fps 22
}
$sequence "crouch_draw_shotgun" {
	"anims/crouch_draw_shotgun_blend01"
	"anims/crouch_draw_shotgun_blend02"
	blend XR -90 90
	fps 18
}
$sequence "crouch_aim_shotgun" {
	"anims/crouch_aim_shotgun_blend01"
	"anims/crouch_aim_shotgun_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "crouch_shoot_shotgun" {
	"anims/crouch_shoot_shotgun_blend01"
	"anims/crouch_shoot_shotgun_blend02"
	blend XR -90 90
	{ event 5021 0 "51" }
	fps 15
}
$sequence "crouch_reload_shotgun" {
	"anims/crouch_reload_shotgun_blend01"
	"anims/crouch_reload_shotgun_blend02"
	blend XR -90 90
	fps 22
}
$sequence "ref_draw_gauss" {
	"anims/ref_draw_gauss_blend01"
	"anims/ref_draw_gauss_blend02"
	blend XR -90 90
	fps 18
}
$sequence "ref_aim_gauss" {
	"anims/ref_aim_gauss_blend01"
	"anims/ref_aim_gauss_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "ref_shoot_gauss" {
	"anims/ref_shoot_gauss_blend01"
	"anims/ref_shoot_gauss_blend02"
	blend XR -90 90
	{ event 5021 0 "51" }
	fps 20
}
$sequence "crouch_draw_gauss" {
	"anims/crouch_draw_gauss_blend01"
	"anims/crouch_draw_gauss_blend02"
	blend XR -90 90
	fps 18
}
$sequence "crouch_aim_gauss" {
	"anims/crouch_aim_gauss_blend01"
	"anims/crouch_aim_gauss_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "crouch_shoot_gauss" {
	"anims/crouch_shoot_gauss_blend01"
	"anims/crouch_shoot_gauss_blend02"
	blend XR -90 90
	{ event 5021 0 "51" }
	fps 20
}
$sequence "ref_draw_mp5" {
	"anims/ref_draw_mp5_blend01"
	"anims/ref_draw_mp5_blend02"
	blend XR -90 90
	fps 17
}
$sequence "ref_aim_mp5" {
	"anims/ref_aim_mp5_blend01"
	"anims/ref_aim_mp5_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "ref_shoot_mp5" {
	"anims/ref_shoot_mp5_blend01"
	"anims/ref_shoot_mp5_blend02"
	blend XR -90 90
	{ event 5005 0 "muzzle_MP5.txt" }
	fps 30
}
$sequence "ref_reload_mp5" {
	"anims/ref_reload_mp5_blend01"
	"anims/ref_reload_mp5_blend02"
	blend XR -90 90
	fps 16
}
$sequence "crouch_draw_mp5" {
	"anims/crouch_draw_mp5_blend01"
	"anims/crouch_draw_mp5_blend02"
	blend XR -90 90
	fps 17
}
$sequence "crouch_aim_mp5" {
	"anims/crouch_aim_mp5_blend01"
	"anims/crouch_aim_mp5_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "crouch_shoot_mp5" {
	"anims/crouch_shoot_mp5_blend01"
	"anims/crouch_shoot_mp5_blend02"
	blend XR -90 90
	{ event 5005 0 "muzzle_MP5.txt" }
	fps 30
}
$sequence "crouch_reload_mp5" {
	"anims/crouch_reload_mp5_blend01"
	"anims/crouch_reload_mp5_blend02"
	blend XR -90 90
	fps 16
}
$sequence "ref_draw_rpg" {
	"anims/ref_draw_rpg_blend01"
	"anims/ref_draw_rpg_blend02"
	blend XR -90 90
	fps 15
}
$sequence "ref_aim_rpg" {
	"anims/ref_aim_rpg_blend01"
	"anims/ref_aim_rpg_blend02"
	blend XR -90 90
	fps 10
	loop
}
$sequence "ref_shoot_rpg" {
	"anims/ref_shoot_rpg_blend01"
	"anims/ref_shoot_rpg_blend02"
	blend XR -90 90
	fps 18
}
$sequence "ref_reload_rpg" {
	"anims/ref_reload_rpg_blend01"
	"anims/ref_reload_rpg_blend02"
	blend XR -90 90
	fps 13
}
$sequence "crouch_draw_rpg" {
	"anims/crouch_draw_rpg_blend01"
	"anims/crouch_draw_rpg_blend02"
	blend XR -90 90
	fps 15
}
$sequence "crouch_aim_rpg" {
	"anims/crouch_aim_rpg_blend01"
	"anims/crouch_aim_rpg_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "crouch_shoot_rpg" {
	"anims/crouch_shoot_rpg_blend01"
	"anims/crouch_shoot_rpg_blend02"
	blend XR -90 90
	fps 18
}
$sequence "crouch_reload_rpg" {
	"anims/crouch_reload_rpg_blend01"
	"anims/crouch_reload_rpg_blend02"
	blend XR -90 90
	fps 13
}
$sequence "ref_draw_egon" {
	"anims/ref_draw_egon_blend01"
	"anims/ref_draw_egon_blend02"
	blend XR -90 90
	fps 12
}
$sequence "ref_aim_egon" {
	"anims/ref_aim_egon_blend01"
	"anims/ref_aim_egon_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "ref_shoot_egon" {
	"anims/ref_shoot_egon_blend01"
	"anims/ref_shoot_egon_blend02"
	blend XR -90 90
	fps 18
	loop
}
$sequence "crouch_draw_egon" {
	"anims/crouch_draw_egon_blend01"
	"anims/crouch_draw_egon_blend02"
	blend XR -90 90
	fps 12
}
$sequence "crouch_aim_egon" {
	"anims/crouch_aim_egon_blend01"
	"anims/crouch_aim_egon_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "crouch_shoot_egon" {
	"anims/crouch_shoot_egon_blend01"
	"anims/crouch_shoot_egon_blend02"
	blend XR -90 90
	fps 18
	loop
}
$sequence "ref_draw_snark" {
	"anims/ref_draw_snark_blend01"
	"anims/ref_draw_snark_blend02"
	blend XR -90 90
	fps 20
}
$sequence "ref_aim_snark" {
	"anims/ref_aim_snark_blend01"
	"anims/ref_aim_snark_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "ref_shoot_snark" {
	"anims/ref_shoot_snark_blend01"
	"anims/ref_shoot_snark_blend02"
	blend XR -90 90
	fps 15
}
$sequence "crouch_draw_snark" {
	"anims/crouch_draw_snark_blend01"
	"anims/crouch_draw_snark_blend02"
	blend XR -90 90
	fps 20
}
$sequence "crouch_aim_snark" {
	"anims/crouch_aim_snark_blend01"
	"anims/crouch_aim_snark_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "crouch_shoot_snark" {
	"anims/crouch_shoot_snark_blend01"
	"anims/crouch_shoot_snark_blend02"
	blend XR -90 90
	fps 15
}
$sequence "ref_draw_hive" {
	"anims/ref_draw_hive_blend01"
	"anims/ref_draw_hive_blend02"
	blend XR -90 90
	fps 12
}
$sequence "ref_aim_hive" {
	"anims/ref_aim_hive_blend01"
	"anims/ref_aim_hive_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "ref_shoot_hive" {
	"anims/ref_shoot_hive_blend01"
	"anims/ref_shoot_hive_blend02"
	blend XR -90 90
	{ event 5021 0 "51" }
	fps 17
}
$sequence "crouch_draw_hive" {
	"anims/crouch_draw_hive_blend01"
	"anims/crouch_draw_hive_blend02"
	blend XR -90 90
	fps 12
}
$sequence "crouch_aim_hive" {
	"anims/crouch_aim_hive_blend01"
	"anims/crouch_aim_hive_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "crouch_shoot_hive" {
	"anims/crouch_shoot_hive_blend01"
	"anims/crouch_shoot_hive_blend02"
	blend XR -90 90
	{ event 5021 0 "51" }
	fps 17
}
$sequence "ref_draw_bow" {
	"anims/ref_draw_bow_blend01"
	"anims/ref_draw_bow_blend02"
	blend XR -90 90
	fps 15
}
$sequence "ref_aim_bow" {
	"anims/ref_aim_bow_blend01"
	"anims/ref_aim_bow_blend02"
	blend XR -90 90
	fps 10
	loop
}
$sequence "ref_shoot_bow" {
	"anims/ref_shoot_bow_blend01"
	"anims/ref_shoot_bow_blend02"
	blend XR -90 90
	{ event 5021 0 "51" }
	fps 20
}
$sequence "ref_aim_bowscope" {
	"anims/ref_aim_bowscope_blend01"
	"anims/ref_aim_bowscope_blend02"
	blend XR -90 90
	fps 6
	loop
}
$sequence "ref_shoot_bowscope" {
	"anims/ref_shoot_bowscope_blend01"
	"anims/ref_shoot_bowscope_blend02"
	blend XR -90 90
	{ event 5021 0 "51" }
	fps 20
}
$sequence "ref_reload_bow" {
	"anims/ref_reload_bow_blend01"
	"anims/ref_reload_bow_blend02"
	blend XR -90 90
	fps 11
}
$sequence "crouch_draw_bow" {
	"anims/crouch_draw_bow_blend01"
	"anims/crouch_draw_bow_blend02"
	blend XR -90 90
	fps 15
}
$sequence "crouch_aim_bow" {
	"anims/crouch_aim_bow_blend01"
	"anims/crouch_aim_bow_blend02"
	blend XR -90 90
	fps 10
	loop
}
$sequence "crouch_shoot_bow" {
	"anims/crouch_shoot_bow_blend01"
	"anims/crouch_shoot_bow_blend02"
	blend XR -90 90
	{ event 5021 0 "51" }
	fps 20
}
$sequence "crouch_aim_bowscope" {
	"anims/crouch_aim_bowscope_blend01"
	"anims/crouch_aim_bowscope_blend02"
	blend XR -90 90
	fps 6
	loop
}
$sequence "crouch_shoot_bowscope" {
	"anims/crouch_shoot_bowscope_blend01"
	"anims/crouch_shoot_bowscope_blend02"
	blend XR -90 90
	{ event 5021 0 "51" }
	fps 20
}
$sequence "crouch_reload_bow" {
	"anims/crouch_reload_bow_blend01"
	"anims/crouch_reload_bow_blend02"
	blend XR -90 90
	fps 11
}
$sequence "ref_draw_minigun" {
	"anims/ref_draw_minigun_blend01"
	"anims/ref_draw_minigun_blend02"
	blend XR -90 90
	fps 15
}
$sequence "ref_aim_minigun" {
	"anims/ref_aim_minigun_blend01"
	"anims/ref_aim_minigun_blend02"
	blend XR -90 90
	fps 8
	loop
}
$sequence "ref_aim_minigun_1" {
	"anims/ref_aim_minigun_1_blend01"
	"anims/ref_aim_minigun_1_blend02"
	blend XR -90 90
	fps 30
}
$sequence "crouch_draw_minigun" {
	"anims/crouch_draw_minigun_blend01"
	"anims/crouch_draw_minigun_blend02"
	blend XR -90 90
	fps 12
}
$sequence "crouch_aim_minigun" {
	"anims/crouch_aim_minigun_blend01"
	"anims/crouch_aim_minigun_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "crouch_shoot_minigun" {
	"anims/crouch_shoot_minigun_blend01"
	"anims/crouch_shoot_minigun_blend02"
	blend XR -90 90
	fps 18
	loop
}
$sequence "ref_draw_uzis" {
	"anims/ref_draw_uzis_blend01"
	"anims/ref_draw_uzis_blend02"
	blend XR -90 90
	fps 10
}
$sequence "ref_draw_uzis_left" {
	"anims/ref_draw_uzis_left_blend01"
	"anims/ref_draw_uzis_left_blend02"
	blend XR -90 90
	fps 11
}
$sequence "ref_aim_uzis" {
	"anims/ref_aim_uzis_blend01"
	"anims/ref_aim_uzis_blend02"
	blend XR -90 90
	fps 14
	loop
}
$sequence "ref_shoot_uzis_both" {
	"anims/ref_shoot_uzis_both_blend01"
	"anims/ref_shoot_uzis_both_blend02"
	blend XR -90 90
	fps 24
}
$sequence "ref_shoot_uzis_right" {
	"anims/ref_shoot_uzis_right_blend01"
	"anims/ref_shoot_uzis_right_blend02"
	blend XR -90 90
	fps 24
}
$sequence "ref_shoot_uzis_left" {
	"anims/ref_shoot_uzis_left_blend01"
	"anims/ref_shoot_uzis_left_blend02"
	blend XR -90 90
	fps 24
}
$sequence "ref_reload_uzis_left" {
	"anims/ref_reload_uzis_left_blend01"
	"anims/ref_reload_uzis_left_blend02"
	blend XR -90 90
	fps 14
}
$sequence "ref_reload_uzis_right" {
	"anims/ref_reload_uzis_right_blend01"
	"anims/ref_reload_uzis_right_blend02"
	blend XR -90 90
	fps 14
}
$sequence "crouch_draw_uzis" {
	"anims/crouch_draw_uzis_blend01"
	"anims/crouch_draw_uzis_blend02"
	blend XR -90 90
	fps 10
}
$sequence "crouch_draw_uzis_left" {
	"anims/crouch_draw_uzis_left_blend01"
	"anims/crouch_draw_uzis_left_blend02"
	blend XR -90 90
	fps 11
}
$sequence "crouch_aim_uzis" {
	"anims/crouch_aim_uzis_blend01"
	"anims/crouch_aim_uzis_blend02"
	blend XR -90 90
	fps 14
	loop
}
$sequence "crouch_shoot_uzis_both" {
	"anims/crouch_shoot_uzis_both_blend01"
	"anims/crouch_shoot_uzis_both_blend02"
	blend XR -90 90
	fps 24
}
$sequence "crouch_shoot_uzis_right" {
	"anims/crouch_shoot_uzis_right_blend01"
	"anims/crouch_shoot_uzis_right_blend02"
	blend XR -90 90
	fps 24
}
$sequence "crouch_shoot_uzis_left" {
	"anims/crouch_shoot_uzis_left_blend01"
	"anims/crouch_shoot_uzis_left_blend02"
	blend XR -90 90
	fps 24
}
$sequence "crouch_reload_uzis_left" {
	"anims/crouch_reload_uzis_left_blend01"
	"anims/crouch_reload_uzis_left_blend02"
	blend XR -90 90
	fps 14
}
$sequence "crouch_reload_uzis_right" {
	"anims/crouch_reload_uzis_right_blend01"
	"anims/crouch_reload_uzis_right_blend02"
	blend XR -90 90
	fps 14
}
$sequence "ref_draw_m16" {
	"anims/ref_draw_m16_blend01"
	"anims/ref_draw_m16_blend02"
	blend XR -90 90
	fps 35
}
$sequence "ref_aim_m16" {
	"anims/ref_aim_m16_blend01"
	"anims/ref_aim_m16_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "ref_shoot_m16" {
	"anims/ref_shoot_m16_blend01"
	"anims/ref_shoot_m16_blend02"
	blend XR -90 90
	{ event 5005 0 "muzzle_spaw.txt" }
	fps 30
}
$sequence "ref_shoot_m203" {
	"anims/ref_shoot_m203_blend01"
	"anims/ref_shoot_m203_blend02"
	blend XR -90 90
	fps 30
}
$sequence "ref_reload_m16" {
	"anims/ref_reload_m16_blend01"
	"anims/ref_reload_m16_blend02"
	blend XR -90 90
	fps 32
}
$sequence "ref_reload_m203" {
	"anims/ref_reload_m203_blend01"
	"anims/ref_reload_m203_blend02"
	blend XR -90 90
	fps 35
}
$sequence "crouch_draw_m16" {
	"anims/crouch_draw_m16_blend01"
	"anims/crouch_draw_m16_blend02"
	blend XR -90 90
	fps 35
}
$sequence "crouch_aim_m16" {
	"anims/crouch_aim_m16_blend01"
	"anims/crouch_aim_m16_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "crouch_shoot_m16" {
	"anims/crouch_shoot_m16_blend01"
	"anims/crouch_shoot_m16_blend02"
	blend XR -90 90
	{ event 5005 0 "muzzle_spaw.txt" }
	fps 30
}
$sequence "crouch_shoot_m203" {
	"anims/crouch_shoot_m203_blend01"
	"anims/crouch_shoot_m203_blend02"
	blend XR -90 90
	fps 30
}
$sequence "crouch_reload_m16" {
	"anims/crouch_reload_m16_blend01"
	"anims/crouch_reload_m16_blend02"
	blend XR -90 90
	fps 32
}
$sequence "crouch_reload_m203" {
	"anims/crouch_reload_m203_blend01"
	"anims/crouch_reload_m203_blend02"
	blend XR -90 90
	fps 35
}
$sequence "ref_draw_sniper" {
	"anims/ref_draw_sniper_blend01"
	"anims/ref_draw_sniper_blend02"
	blend XR -90 90
	fps 15
}
$sequence "ref_aim_sniper" {
	"anims/ref_aim_sniper_blend01"
	"anims/ref_aim_sniper_blend02"
	blend XR -90 90
	fps 10
	loop
}
$sequence "ref_shoot_sniper" {
	"anims/ref_shoot_sniper_blend01"
	"anims/ref_shoot_sniper_blend02"
	blend XR -90 90
	{ event 5021 0 "51" }
	fps 20
}
$sequence "ref_aim_sniperscope" {
	"anims/ref_aim_sniperscope_blend01"
	"anims/ref_aim_sniperscope_blend02"
	blend XR -90 90
	fps 6
	loop
}
$sequence "ref_shoot_sniperscope" {
	"anims/ref_shoot_sniperscope_blend01"
	"anims/ref_shoot_sniperscope_blend02"
	blend XR -90 90
	{ event 5021 0 "51" }
	fps 20
}
$sequence "ref_reload_sniper" {
	"anims/ref_reload_sniper_blend01"
	"anims/ref_reload_sniper_blend02"
	blend XR -90 90
	fps 22
}
$sequence "crouch_draw_sniper" {
	"anims/crouch_draw_sniper_blend01"
	"anims/crouch_draw_sniper_blend02"
	blend XR -90 90
	fps 15
}
$sequence "crouch_aim_sniper" {
	"anims/crouch_aim_sniper_blend01"
	"anims/crouch_aim_sniper_blend02"
	blend XR -90 90
	fps 10
	loop
}
$sequence "crouch_shoot_sniper" {
	"anims/crouch_shoot_sniper_blend01"
	"anims/crouch_shoot_sniper_blend02"
	blend XR -90 90
	{ event 5021 0 "51" }
	fps 20
}
$sequence "crouch_aim_sniperscope" {
	"anims/crouch_aim_sniperscope_blend01"
	"anims/crouch_aim_sniperscope_blend02"
	blend XR -90 90
	fps 6
	loop
}
$sequence "crouch_shoot_sniperscope" {
	"anims/crouch_shoot_sniperscope_blend01"
	"anims/crouch_shoot_sniperscope_blend02"
	blend XR -90 90
	{ event 5021 0 "51" }
	fps 20
}
$sequence "crouch_reload_sniper" {
	"anims/crouch_reload_sniper_blend01"
	"anims/crouch_reload_sniper_blend02"
	blend XR -90 90
	fps 22
}
$sequence "ref_draw_saw" {
	"anims/ref_draw_saw_blend01"
	"anims/ref_draw_saw_blend02"
	blend XR -90 90
	fps 24
}
$sequence "ref_aim_saw" {
	"anims/ref_aim_saw_blend01"
	"anims/ref_aim_saw_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "ref_shoot_saw" {
	"anims/ref_shoot_saw_blend01"
	"anims/ref_shoot_saw_blend02"
	blend XR -90 90
	{ event 5021 0 "51" }
	fps 24
}
$sequence "ref_reload_saw" {
	"anims/ref_reload_saw_blend01"
	"anims/ref_reload_saw_blend02"
	blend XR -90 90
	fps 29
}
$sequence "crouch_draw_saw" {
	"anims/crouch_draw_saw_blend01"
	"anims/crouch_draw_saw_blend02"
	blend XR -90 90
	fps 24
}
$sequence "crouch_aim_saw" {
	"anims/crouch_aim_saw_blend01"
	"anims/crouch_aim_saw_blend02"
	blend XR -90 90
	fps 12
	loop
}
$sequence "crouch_shoot_saw" {
	"anims/crouch_shoot_saw_blend01"
	"anims/crouch_shoot_saw_blend02"
	blend XR -90 90
	{ event 5021 0 "51" }
	fps 24
}
$sequence "crouch_reload_saw" {
	"anims/crouch_reload_saw_blend01"
	"anims/crouch_reload_saw_blend02"
	blend XR -90 90
	fps 29
}
$sequence "deadback" {
	"anims/deadback_blend01"
	"anims/deadback_blend02"
	blend XR -90 90
	fps 10
}
$sequence "deadsitting" {
	"anims/deadsitting_blend01"
	"anims/deadsitting_blend02"
	blend XR -90 90
	fps 10
}
$sequence "deadstomach" {
	"anims/deadstomach_blend01"
	"anims/deadstomach_blend02"
	blend XR -90 90
	fps 10
}
$sequence "deadtable" {
	"anims/deadtable_blend01"
	"anims/deadtable_blend02"
	blend XR -90 90
	fps 10
}
$sequence "phone2" {
	"anims/phone2"
	fps 30
}
$sequence "player_anim_barnaclepull" {
	"anims/player_anim_barnaclepull"
	ACT_40 1
	fps 15
}
$sequence "player_anim_barnaclepull_1" {
	"anims/player_anim_barnaclepull_1"
	ACT_41 1
	fps 15
	loop
}
$sequence "player_anim_barnaclepull_2" {
	"anims/player_anim_barnaclepull_2"
	ACT_42 1
	fps 15
}
$sequence "player_anim_barnaclepull_3" {
	"anims/player_anim_barnaclepull_3"
	ACT_43 1
	fps 15
	loop
}
$sequence "NorthernSoulSpin" {
	"anims/NorthernSoulSpin"
	fps 30
	loop
}
$sequence "Laying_pose" {
	"anims/Laying_pose_blend01"
	"anims/Laying_pose_blend02"
	blend XR -90 90
	fps 30
	loop
}
$sequence "Laying_pose2" {
	"anims/Laying_pose2_blend01"
	"anims/Laying_pose2_blend02"
	blend XR -90 90
	fps 30
	loop
}
$sequence "liecomfy" {
	"anims/liecomfy_blend01"
	"anims/liecomfy_blend02"
	blend XR -90 90
	fps 30
	loop
}
$sequence "liedown" {
	"anims/liedown_blend01"
	"anims/liedown_blend02"
	blend XR -90 90
	fps 30
	loop
}
$sequence "Sitting" {
	"anims/Sitting_blend01"
	"anims/Sitting_blend02"
	blend XR -90 90
	fps 30
	loop
}
$sequence "Thankfull" {
	"anims/Thankfull"
	fps 30
	loop
}
$sequence "Clapping" {
	"anims/Clapping_blend01"
	"anims/Clapping_blend02"
	blend XR -90 90
	fps 30
	loop
}
$sequence "Excited" {
	"anims/Excited"
	fps 25
	loop
}
$sequence "Rejected" {
	"anims/Rejected"
	fps 30
	loop
}
$sequence "Angry" {
	"anims/Angry"
	fps 30
	loop
}
$sequence "Petting" {
	"anims/Petting"
	fps 20
}
$sequence "looking" {
	"anims/looking"
	fps 21
	loop
}
$sequence "waving" {
	"anims/waving"
	fps 30
	loop
}
$sequence "standing_greeting" {
	"anims/standing_greeting"
	fps 30
	loop
}
$sequence "funky" {
	"anims/funky"
	fps 30
	loop
}
$sequence "hiphopdance" {
	"anims/hiphopdance"
	fps 21
	loop
}
$sequence "floss" {
	"anims/floss"
	fps 21
	loop
}
$sequence "drivin" {
	"anims/drivin"
	fps 21
	loop
}
$sequence "caramelldansen" {
	"anims/caramelldansen"
	fps 21
	loop
}
$sequence "macarena" {
	"anims/macarena"
	fps 21
	loop
}
$sequence "yorha_type_e" {
	"anims/yorha_type_e_blend01"
	"anims/yorha_type_e_blend02"
	blend XR -90 90
	fps 30
	loop
}

// End of QC script.
