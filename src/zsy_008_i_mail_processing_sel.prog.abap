*&---------------------------------------------------------------------*
*& Include          ZOT_29_I_MAIL_PROCESSING_SEL
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

*  SELECT-OPTIONS: s_vbeln FOR likp-vbeln.
PARAMETERS: p_vbeln type vbeln_vl.

SELECTION-SCREEN END OF BLOCK b1.
