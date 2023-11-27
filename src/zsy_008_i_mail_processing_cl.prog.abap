*&---------------------------------------------------------------------*
*& Include          ZOT_29_I_MAIL_PROCESSING_CL
*&---------------------------------------------------------------------*

CLASS lcl_main DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      get_instance
        RETURNING
          VALUE(ro_instance) TYPE REF TO lcl_main.

    METHODS: get_data,
      send_mail,
      get_data_sh,
      f4.

    DATA: mo_gbt         TYPE REF TO cl_gbt_multirelated_service,
          mo_bcs         TYPE REF TO cl_bcs,
          mo_doc_bcs     TYPE REF TO cl_document_bcs,
          mo_recipient   TYPE REF TO if_recipient_bcs,
          mt_soli        TYPE TABLE OF soli,
          ms_soli        TYPE soli,
          mv_status      TYPE bcs_rqst,
          mv_content     TYPE string,
          mo_bcs_convert TYPE REF TO cl_bcs_convert,
          binary_content TYPE solix_tab,
          size           TYPE so_obj_len,
          mv_att_data    TYPE string,
          lv_exception   TYPE REF TO cx_root,
          cc             TYPE xfeld,
          bcc            TYPE xfeld.

    CLASS-DATA:
      mo_instance TYPE REF TO lcl_main.

ENDCLASS.

CLASS lcl_main IMPLEMENTATION.

  METHOD get_instance.   "singleton yapısı

    IF mo_instance IS INITIAL.
      mo_instance = NEW #( ).
    ENDIF.
    ro_instance = mo_instance.

  ENDMETHOD.

  METHOD get_data.

    SELECT lips~vbeln,
           lips~posnr,
           lips~matnr,
           lips~ntgew,
           lips~brgew,
           lips~gewei FROM lips
      INNER JOIN  likp ON  likp~vbeln EQ lips~vbeln
        WHERE likp~vbeln = @p_vbeln
          INTO CORRESPONDING FIELDS OF TABLE @gt_data.

  ENDMETHOD.

  METHOD send_mail.

    mo_gbt = NEW cl_gbt_multirelated_service(
*    codepage =
    ).

    mv_content = '<!DOCTYPE html>'    "mail içeriğini ve tablonun başlığını ekledik
             && '<html>'
             && '<head>'
             && '<style>'
             && 'table, th, td {'
             && 'border: 1px solid ;'
             && '}'
             && '</style>'
             && '<meta charset="utf-8">'
             && '<bddy>Sayın İlgili,'
             && '<p>'
             && p_vbeln
             && ' teslimatın malzeme bazında brüt ve net ağırlığı aşağıdaki şekildedir.'
             &&'</p>'
             &&'<table>'
             && '<tr>'
             && '<th>MATNR</th>'
             && '<th>NTGEW</th>'
             && '<th>BRGEW</th>'
             && '<th>GEWEI</th>'
             && '</tr>'.

    LOOP AT gt_data ASSIGNING FIELD-SYMBOL(<lfs_data>). "tablonun verileri
      mv_content = mv_content && '<tr>'
                              && '<th>' && <lfs_data>-matnr && '</th>'
                              && '<th>' && <lfs_data>-ntgew && '</th>'
                              && '<th>' && <lfs_data>-brgew && '</th>'
                              && '<th>' && <lfs_data>-gewei && '</th>'
                              && '</tr>'.
    ENDLOOP.

    mv_content = mv_content  && '</table>'
                             && '<p> Teşekkürler. </p> '
                             && '</body>'
                             && '</html>'.
    TRY.
        mt_soli = cl_document_bcs=>string_to_soli( mv_content ).

        CALL METHOD mo_gbt->set_main_html
          EXPORTING
            content = mt_soli
*           filename    =
*           description =
          .

        mo_doc_bcs = cl_document_bcs=>create_from_multirelated(
                       i_subject          = 'Mail Processing'
*                   i_language         = space
*                   i_importance       =
*                   i_sensitivity      =
                       i_multirel_service = mo_gbt
*                   iv_vsi_profile     =
                     ).

        LOOP AT gt_data INTO DATA(ls_data).

          lv_ntgew = ls_data-ntgew.
          lv_brgew = ls_data-brgew.

          IF sy-tabix EQ 1.
            CONCATENATE 'Teslimat Numarası'
                        'Kalem Numarası'
                        'Malzeme Numarası'
                        'Net Ağırlık'
                        'Brüt Ağırlık'
                        'Birim'
                   INTO mv_att_data
                   SEPARATED BY cl_abap_char_utilities=>horizontal_tab. "verileri yan yana hücreye koyar
          ENDIF.

          CONCATENATE ls_data-vbeln
                      ls_data-posnr
                      ls_data-matnr
                      lv_ntgew
                      lv_brgew
                      ls_data-gewei
                 INTO gv_att_line
                 SEPARATED BY cl_abap_char_utilities=>horizontal_tab.

          CONCATENATE mv_att_data
                      gv_att_line
                 INTO mv_att_data
                 SEPARATED BY cl_abap_char_utilities=>newline.  "verileri alt satıra yazar

        ENDLOOP.
        TRY.
            cl_bcs_convert=>string_to_solix(
                   EXPORTING
                     iv_string   = mv_att_data
                     iv_codepage = '4103'
                     iv_add_bom  = 'X'
                   IMPORTING
                     et_solix    = binary_content
                     ev_size     = size  ).
          CATCH cx_bcs INTO DATA(ex).
            MESSAGE ex TYPE 'I' DISPLAY LIKE 'A'.
            RETURN.
        ENDTRY.

        mo_doc_bcs->add_attachment(
          EXPORTING
            i_attachment_type    = 'XLS'
            i_attachment_subject = 'Mail Excel Verileri'
            i_attachment_size    = size
            i_att_content_hex    = binary_content ).

        mo_bcs = cl_bcs=>create_persistent( ). "Mail göndermemizi sağlayan cl_bcs sınıfından create_persistent methodu ile obje alınıyor
        mo_bcs->set_document( i_document = mo_doc_bcs  ).

        READ TABLE gt_data_sh INTO DATA(ls_mail) WITH KEY vbeln = p_vbeln.
        DATA(sender_mail) =  ls_mail-sender_email. "mail göndericisi atanır
        mo_recipient = cl_cam_address_bcs=>create_internet_address( "'info@nttdata.com'
          i_address_string = ls_mail-sender_email
        ).

        mo_bcs->add_recipient(
       EXPORTING
         i_recipient  = mo_recipient
         i_express    = abap_true
         i_copy       = cc
         i_blind_copy = bcc
         i_no_forward = ' '
     ).

        mv_status = 'N'.
        CALL METHOD mo_bcs->set_status_attributes
          EXPORTING
            i_requested_status = mv_status.

        mo_bcs->send( ).

        COMMIT WORK.

      CATCH cx_address_bcs INTO lv_exception.
        MESSAGE lv_exception->get_text( ) TYPE 'I' DISPLAY LIKE 'E'.
        RETURN.

      CATCH cx_send_req_bcs INTO lv_exception.
        MESSAGE lv_exception->get_text( ) TYPE 'I' DISPLAY LIKE 'E'.
        RETURN.

      CATCH cx_gbt_mime INTO lv_exception.
        MESSAGE lv_exception->get_text( ) TYPE 'I' DISPLAY LIKE 'E'.
        RETURN.

      CATCH cx_bcom_mime INTO lv_exception.
        MESSAGE lv_exception->get_text( ) TYPE 'I' DISPLAY LIKE 'E'.
        RETURN.

      CATCH cx_document_bcs INTO lv_exception.
        MESSAGE lv_exception->get_text( ) TYPE 'I' DISPLAY LIKE 'E'.
        RETURN.
    ENDTRY.

    IF sy-subrc EQ 0.
      MESSAGE i010(zot_29).
    ENDIF.

    IF sy-subrc NE 0.
      MESSAGE i009(zot_29).
    ENDIF.

  ENDMETHOD.

  METHOD get_data_sh.

    SELECT vbeln,
    sender_email,
    cc,
    bcc FROM zot_29_t_bk1
      INTO CORRESPONDING FIELDS OF TABLE @gt_data_sh.

    IF sy-subrc IS INITIAL.
      SORT gt_data_sh.
    ENDIF.

  ENDMETHOD.

  METHOD f4.

    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield        = 'VBELN'
        dynpprog        = sy-repid
        dynpnr          = sy-dynnr
        dynprofield     = 'P_VBELN'
        value_org       = 'S'
      TABLES
        value_tab       = gt_data_sh
*       FIELD_TAB       =
        return_tab      = return_tab
*       DYNPFLD_MAPPING =
      EXCEPTIONS
        parameter_error = 1
        no_values_found = 2
        OTHERS          = 3.
    IF sy-subrc = 0.
      READ TABLE return_tab INTO DATA(ls_return) INDEX 1.
      IF sy-subrc EQ 0.
        p_vbeln = ls_return-fieldval.
      ENDIF.
    ELSE.
      MESSAGE i008(zot_29).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
