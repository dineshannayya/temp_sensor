#tapcell \
#  -endcap_cpp "2" \
#  -distance 14 \
#  -tapcell_master "sky130_fd_sc_hd__tapvpwrvgnd_1" \
#  -endcap_master "sky130_fd_sc_hd__decap_4"

tapcell\
    -distance $::env(FP_TAPCELL_DIST)\
    -tapcell_master "$::env(FP_WELLTAP_CELL)"\
    -endcap_master "$::env(FP_ENDCAP_CELL)"\
    -halo_width_x $::env(FP_TAP_HORIZONTAL_HALO)\
    -halo_width_y $::env(FP_TAP_VERTICAL_HALO)


# endcap_cpp = contacted poly pitch (now deprecated)
