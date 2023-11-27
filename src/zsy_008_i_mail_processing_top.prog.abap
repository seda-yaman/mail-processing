*&---------------------------------------------------------------------*
*& Include          ZOT_29_I_MAIL_PROCESSING_TOP
*&---------------------------------------------------------------------*

TABLES: likp, lips.

CLASS lcl_main DEFINITION DEFERRED.

DATA: go_class TYPE REF TO lcl_main.

DATA : return_tab TYPE TABLE OF ddshretval,
       gt_data_sh TYPE TABLE OF zot_29_t_bk1.

TYPES: BEGIN OF gty_type,
         vbeln TYPE vbeln_vl,
         posnr TYPE posnr_vl,
         matnr TYPE matnr,
         ntgew TYPE ntgew_15,
         brgew TYPE brgew_15,
         gewei TYPE gewei,
       END OF gty_type.

DATA: gt_data TYPE TABLE OF gty_type.

DATA gv_att_line TYPE string.
DATA lv_ntgew TYPE string.
DATA lv_brgew TYPE string.
