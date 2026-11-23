(globals
    version = 3
    io_order = default
)
(iopad
    (left
        (inst  name="u_pad_sclk"     cell="PADDI"     offset=240 )
        (inst  name="u_pad_aresetn"  cell="PADDI"     offset=300 )
        (inst  name="u_pad_vss0"     cell="PADVSS"    offset=360 )
        (inst  name="u_pad_vdd0"     cell="PADVDD"    offset=420 )
        (inst  name="u_pad_aclk"     cell="PADDI"     offset=480 )
    )
    (topleft
        (inst  name="CORNER_TL" cell="padIORINGCORNER")
    )
    (top
        (inst  name="u_pad_gpio0"    cell="PADDO"     offset=240 )
        (inst  name="u_pad_gpio1"    cell="PADDO"     offset=300 )
        (inst  name="u_pad_vddior"   cell="PADVDDIOR" offset=360 )
        (inst  name="u_pad_gpio2"    cell="PADDO"     offset=420 )
        (inst  name="u_pad_gpio3"    cell="PADDO"     offset=480 )
    )
    (topright
        (inst  name="CORNER_TR" cell="padIORINGCORNER")
    )
    (right
        (inst  name="u_pad_miso"     cell="PADDO"     offset=240 )
        (inst  name="u_pad_vss1"     cell="PADVSS"    offset=300 )
        (inst  name="u_pad_vdd1"     cell="PADVDD"    offset=360 )
        (inst  name="u_pad_mosi"     cell="PADDI"     offset=420 )
        (inst  name="u_pad_cs_n"     cell="PADDI"     offset=480 )
    )
    (bottomright
        (inst  name="CORNER_BR" cell="padIORINGCORNER")
    )
    (bottom
        (inst  name="u_pad_gpio4"    cell="PADDO"     offset=240 )
        (inst  name="u_pad_gpio5"    cell="PADDO"     offset=300 )
        (inst  name="u_pad_vssior"   cell="PADVSSIOR" offset=360 )
        (inst  name="u_pad_gpio6"    cell="PADDO"     offset=420 )
        (inst  name="u_pad_gpio7"    cell="PADDO"     offset=480 )
    )
    (bottomleft
        (inst  name="CORNER_BL" cell="padIORINGCORNER")
    )
)
