*&---------------------------------------------------------------------*
*& Report ZOT_29_P_MAIL_PROCESSING
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zsy_008_p_mail_processing.

INCLUDE zsy_008_i_mail_processing_top.
INCLUDE zsy_008_i_mail_processing_sel.
INCLUDE zsy_008_i_mail_processing_cl.

INITIALIZATION.
  go_class = lcl_main=>get_instance( ).

  go_class->get_data_sh( ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_vbeln.
  go_class->f4( ).

START-OF-SELECTION.
  go_class->get_data( ).
  go_class->send_mail( ).
