prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- Oracle APEX export file
--
-- You should run this script using a SQL client connected to the database as
-- the owner (parsing schema) of the application or as a database user with the
-- APEX_ADMINISTRATOR_ROLE role.
--
-- This export file has been automatically generated. Modifying this file is not
-- supported by Oracle and can lead to unexpected application and/or instance
-- behavior now or in the future.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_imp.import_begin (
 p_version_yyyy_mm_dd=>'2026.03.30'
,p_release=>'26.1.0'
,p_default_workspace_id=>8747817710043504
,p_default_application_id=>132
,p_default_id_offset=>0
,p_default_owner=>'TEST'
);
end;
/
 
prompt APPLICATION 132 - watchtower
--
-- Application Export:
--   Application:     132
--   Name:            watchtower
--   Date and Time:   10:29 Monday October 5, 2026
--   Exported By:     TEST
--   Flashback:       0
--   Export Type:     Component Export
--   Manifest
--     PLUGIN: 15844765216620605
--   Manifest End
--   Version:         26.1.0
--   Instance ID:     939566546695539
--

begin
  -- replace components
  wwv_flow_imp.g_mode := 'REPLACE';
end;
/
prompt --application/shared_components/plugins/item_type/com_cemsm_magnet_slider
begin
wwv_flow_imp_shared.create_plugin(
 p_id=>wwv_flow_imp.id(15844765216620605)
,p_plugin_type=>'ITEM TYPE'
,p_name=>'COM_CEMSM_MAGNET_SLIDER'
,p_display_name=>'Magnet Slider'
,p_apexlang_name=>'apexMagnetSlider'
,p_supported_component_types=>'APEX_APPLICATION_PAGE_ITEMS'
,p_javascript_file_urls=>'#PLUGIN_FILES#apex-magnet-slider#MIN#.js'
,p_css_file_urls=>'#PLUGIN_FILES#apex-magnet-slider#MIN#.css'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- APEX_MAGNET_SLIDER 0.1.0',
'-- Render Function: magnet_render | Validation Function: magnet_validate',
'',
'function magnet_number(p_text in varchar2) return number is',
'    l_text varchar2(32767) := trim(p_text);',
'    l_digits varchar2(32767);',
'    l_dot pls_integer;',
'    l_result number;',
'begin',
'    if l_text is null or not regexp_like(l_text, ''^-?(0|[1-9][0-9]*)([.][0-9]{1,6})?$'') then',
'        raise_application_error(-20001, ''Magnet: use plain numbers with at most 6 decimal places.'');',
'    end if;',
'    l_digits := replace(l_text, ''-'', '''');',
'    l_dot := instr(l_digits, ''.'');',
'    l_result := to_number(replace(l_digits, ''.'', ''''), ''9999999999999999'');',
'    if l_dot > 0 then l_result := l_result / power(10, length(l_digits) - l_dot); end if;',
'    if substr(l_text, 1, 1) = ''-'' then l_result := -l_result; end if;',
'    if abs(l_result) > 1000000000 then',
'        raise_application_error(-20001, ''Magnet: numbers must be within +/-1 billion.'');',
'    end if;',
'    return l_result;',
'end;',
'',
'function magnet_stops(p_item in apex_plugin.t_item) return apex_t_number is',
'    l_values apex_t_number := apex_t_number();',
'    l_parts apex_t_varchar2;',
'    l_min number;',
'    l_max number;',
'    l_step number;',
'    l_count number;',
'    l_mode varchar2(30) := nvl(p_item.attributes.get_varchar2(''mode''), ''single'');',
'begin',
'    if l_mode not in (''single'', ''range'') then',
'        raise_application_error(-20001, ''Magnet: mode must be single or range.'');',
'    end if;',
'    if trim(p_item.attributes.get_varchar2(''custom_stops'')) is not null then',
'        l_parts := apex_string.split(p_item.attributes.get_varchar2(''custom_stops''), '','');',
'        if l_parts.count < 2 or l_parts.count > 1001 then',
'            raise_application_error(-20001, ''Magnet: configure 2 to 1001 stops.'');',
'        end if;',
'        for i in 1 .. l_parts.count loop',
'            l_values.extend;',
'            l_values(i) := magnet_number(l_parts(i));',
'            if i > 1 and l_values(i) <= l_values(i-1) then',
'                raise_application_error(-20001, ''Magnet: custom stops must be unique and increasing.'');',
'            end if;',
'        end loop;',
'    else',
'        l_min := magnet_number(nvl(p_item.attributes.get_varchar2(''minimum''), ''0''));',
'        l_max := magnet_number(nvl(p_item.attributes.get_varchar2(''maximum''), ''100''));',
'        l_step := magnet_number(nvl(p_item.attributes.get_varchar2(''step''), ''10''));',
'        if l_step <= 0 or l_max <= l_min then',
'            raise_application_error(-20001, ''Magnet: max must exceed min and step must be positive.'');',
'        end if;',
'        l_count := (l_max-l_min)/l_step + 1;',
'        if l_count <> trunc(l_count) or l_count > 1001 then',
'            raise_application_error(-20001, ''Magnet: step must divide the interval exactly; maximum 1001 stops.'');',
'        end if;',
'        for i in 0 .. l_count-1 loop',
'            l_values.extend; l_values(l_values.count) := l_min+i*l_step;',
'        end loop;',
'    end if;',
'    return l_values;',
'end;',
'',
'-- Shared check: returns an error message, or null if the value is fine.',
'function magnet_check(p_item in apex_plugin.t_item, p_value in varchar2) return varchar2 is',
'    l_values apex_t_number := magnet_stops(p_item);',
'    l_parts apex_t_varchar2;',
'    l_current number;',
'    l_previous number;',
'    l_found boolean;',
'    l_expected pls_integer := case when p_item.attributes.get_varchar2(''mode'') = ''range'' then 2 else 1 end;',
'    e_bad_value exception;',
'begin',
'    if p_value is null then',
'        if p_item.is_required then raise e_bad_value; end if;',
'        return null;',
'    end if;',
'    l_parts := apex_string.split(p_value, '':'');',
'    if l_parts.count <> l_expected then raise e_bad_value; end if;',
'    for i in 1 .. l_parts.count loop',
'        begin',
'            l_current := magnet_number(l_parts(i));',
'        exception when others then raise e_bad_value;',
'        end;',
'        l_found := false;',
'        for j in 1 .. l_values.count loop',
'            if l_current = l_values(j) then l_found := true; exit; end if;',
'        end loop;',
'        if not l_found then raise e_bad_value; end if;',
'        if i > 1 and l_current < l_previous then raise e_bad_value; end if;',
'        l_previous := l_current;',
'    end loop;',
'    return null;',
'exception',
'    when e_bad_value then',
'        return case when l_expected = 2',
'            then ''Choose two allowed numbers in ascending order.''',
'            else ''Choose an allowed number.'' end;',
'end;',
'',
'procedure magnet_validate(',
'    p_item   in apex_plugin.t_item,',
'    p_plugin in apex_plugin.t_plugin,',
'    p_param  in apex_plugin.t_item_validation_param,',
'    p_result in out nocopy apex_plugin.t_item_validation_result',
') is',
'    l_msg varchar2(4000) := magnet_check(p_item, p_param.value);',
'begin',
'    if l_msg is not null then',
'        p_result.message          := l_msg;',
'        p_result.display_location := apex_plugin.c_inline_with_field_and_notif;',
'    end if;',
'end;',
'',
'procedure magnet_render(',
'    p_item   in apex_plugin.t_item,',
'    p_plugin in apex_plugin.t_plugin,',
'    p_param  in apex_plugin.t_item_render_param,',
'    p_result in out nocopy apex_plugin.t_item_render_result',
') is',
'    l_values apex_t_number := magnet_stops(p_item);',
'    l_json varchar2(32767);',
'    l_name varchar2(255);',
'    l_color varchar2(100) := nvl(p_item.attributes.get_varchar2(''accent''), ''#7255e7'');',
'    l_value varchar2(32767) := p_param.value;',
'begin',
'',
'    if p_param.is_readonly or p_param.is_printer_friendly then',
'        apex_plugin_util.print_hidden_if_readonly(',
'            p_item_name           => p_item.name,',
'            p_value               => p_param.value,',
'            p_is_readonly         => p_param.is_readonly,',
'            p_is_printer_friendly => p_param.is_printer_friendly);',
'        sys.htp.p(''<span class="display_only">''||apex_escape.html(',
'            replace(p_param.value, '':'', '' - ''))||''</span>'');',
'        return;',
'    end if;',
'',
'    -- Drop a tampered/invalid stored value so the user can choose again.',
'    if p_param.value is not null and magnet_check(p_item, p_param.value) is not null then',
'        l_value := null;',
'    end if;',
'',
'    l_name := apex_plugin.get_input_name_for_page_item(p_is_multi_value => false);',
'    sys.htp.p(''<input type="hidden" id="''||apex_escape.html_attribute(p_item.name)||',
'        ''" name="''||apex_escape.html_attribute(l_name)||''" value="''||',
'        apex_escape.html_attribute(l_value)||''">'');',
'    if l_value is null and p_param.value is not null then',
'        sys.htp.p(''<span role="alert">The saved or submitted value is not an allowed stop. Please choose again.</span>'');',
'    end if;',
'',
'    if not regexp_like(l_color, ''^#[0-9a-fA-F]{6}$'') then l_color := ''#7255e7''; end if;',
'    apex_json.initialize_clob_output;',
'    apex_json.open_object;',
'    apex_json.write(''mode'', nvl(p_item.attributes.get_varchar2(''mode''), ''single''));',
'    apex_json.open_array(''values'');',
'    for i in 1 .. l_values.count loop apex_json.write(l_values(i)); end loop;',
'    apex_json.close_array;',
'    apex_json.write(''prefix'', substr(p_item.attributes.get_varchar2(''prefix''), 1, 100));',
'    apex_json.write(''suffix'', substr(p_item.attributes.get_varchar2(''suffix''), 1, 100));',
'    apex_json.write(''accent'', l_color);',
'    apex_json.write(''label'', nvl(p_item.plain_label, p_item.name));',
'    apex_json.write(''required'', p_item.is_required);',
'    apex_json.write(''allowClear'', nvl(p_item.attributes.get_varchar2(''allow_clear''), ''Y'') = ''Y'');',
'    apex_json.close_object;',
'    l_json := dbms_lob.substr(apex_json.get_clob_output, 32767, 1);',
'    apex_json.free_output;',
'',
'    apex_javascript.add_onload_code(',
'        p_code => ''MagnetSlider.mount(''||apex_javascript.add_value(p_item.name, false)||',
'                  '',JSON.parse(''||apex_javascript.add_value(l_json, false)||''));'',',
'        p_key  => ''magnet_''||p_item.name);',
'',
'    p_result.is_navigable     := true;',
'    p_result.navigable_dom_id := p_item.name||''_HANDLE_0'';',
'end;'))
,p_api_version=>3
,p_render_function=>'magnet_render'
,p_validation_function=>'magnet_validate'
,p_item_session_state_data_type=>'VARCHAR2'
,p_standard_attributes=>'VISIBLE:SESSION_STATE:READONLY:SOURCE'
,p_version_scn=>'SH256:U15KlRrrtbaHqe3BASclg48QcoaYpvDge0_4p1CkLCk'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'Magnet Slider is an item plug-in that lets users pick a value (or a range) by sliding a handle that snaps to fixed stops.',
'',
'MODES',
'- Single: one handle. The item value is one number, for example 30.',
'- Range: two handles. The item value is stored as lower:upper, for example 20:80. The lower handle cannot pass the upper one.',
'',
'DEFINING THE STOPS',
'Either set Minimum, Maximum and Step, or list the stops yourself in Custom Stops. If Custom Stops has a value, it replaces Minimum, Maximum and Step. Only the defined stops can be selected and submitted. Values outside the stops are rejected by the s'
||'erver-side validation.',
'',
'USER INTERACTION',
'- Drag a handle or click anywhere on the rail to move to the nearest stop.',
'- Keyboard: Left/Right/Up/Down arrows move one stop, Page Up/Page Down move ten, Home and End jump to the first and last stop.',
'- A Clear button resets the item to empty (can be turned off with Allow Clear).',
'',
'SESSION STATE AND VALIDATION',
'- Empty value is stored as null. If the item is required, an empty slider fails validation.',
'- A saved value that is not an allowed stop (for example after you change the stops) is dropped and the user is asked to choose again.',
'- The item fires the standard change event, so Dynamic Actions on Change work as usual.',
'',
'JAVASCRIPT API',
'- apex.item("P1_ITEM").getValue()',
'- apex.item("P1_ITEM").setValue("30") or setValue("20:80") for range',
'- apex.item("P1_ITEM").disable() / enable()',
'',
'LIMITS',
'- Numbers must be plain (no thousand separators), up to 6 decimal places, between -1 billion and 1 billion.',
'- Between 2 and 1001 stops.',
'',
'REQUIREMENTS',
'Oracle APEX 26.1 or later.'))
,p_version_identifier=>'0.1.0'
,p_files_version=>2461319102218
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(15850456844663609)
,p_plugin_id=>wwv_flow_imp.id(15844765216620605)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>8
,p_display_sequence=>80
,p_static_id=>'accent'
,p_prompt=>'Accent'
,p_apexlang_name=>'accent'
,p_attribute_type=>'COLOR'
,p_is_required=>false
,p_default_value=>'#7255e7'
,p_is_translatable=>false
,p_help_text=>'Color used for the handle, the filled part of the rail, the selected value and the thin border around the item. Pick a color with the color picker. If the value is not a valid 6-digit hex color, the default #7255e7 is used.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(15850918046667490)
,p_plugin_id=>wwv_flow_imp.id(15844765216620605)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>9
,p_display_sequence=>90
,p_static_id=>'allow_clear'
,p_prompt=>'Allow Clear'
,p_apexlang_name=>'allowClear'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>false
,p_default_value=>'Y'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>'Yes shows a Clear button so the user can reset the item to empty. No hides it, so once a value is chosen it can only be changed, not removed. Default: Yes.'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(15851884526669958)
,p_plugin_attribute_id=>wwv_flow_imp.id(15850918046667490)
,p_display_sequence=>20
,p_display_value=>'NO'
,p_return_value=>'N'
,p_apexlang_name=>'no'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(15851474335668955)
,p_plugin_attribute_id=>wwv_flow_imp.id(15850918046667490)
,p_display_sequence=>10
,p_display_value=>'YES'
,p_return_value=>'Y'
,p_apexlang_name=>'yes'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(15848962855654582)
,p_plugin_id=>wwv_flow_imp.id(15844765216620605)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_static_id=>'custom_stops'
,p_prompt=>'Custom Stops'
,p_apexlang_name=>'customStops'
,p_attribute_type=>'TEXTAREA'
,p_is_required=>false
,p_is_translatable=>false
,p_help_text=>'Optional. Comma-separated list of the allowed numbers, in increasing order with no duplicates, for example: 0, 5, 10, 25, 50, 100. Use a dot as the decimal separator. Needs 2 to 1001 values. When filled in, it replaces Minimum, Maximum and Step. Leav'
||'e empty to use those instead.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(15847970810648325)
,p_plugin_id=>wwv_flow_imp.id(15844765216620605)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_static_id=>'maximum'
,p_prompt=>'Maximum'
,p_apexlang_name=>'maximum'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'100'
,p_is_translatable=>false
,p_help_text=>'Highest selectable number. Must be greater than Minimum. Plain number, up to 6 decimal places, within +/-1 billion. Default: 100. Ignored when Custom Stops is filled in.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(15847418811646191)
,p_plugin_id=>wwv_flow_imp.id(15844765216620605)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_static_id=>'minimum'
,p_prompt=>'Minimum'
,p_apexlang_name=>'minimum'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'0'
,p_is_translatable=>false
,p_help_text=>'Lowest selectable number. Plain number, up to 6 decimal places, between -1,000,000,000 and 1,000,000,000. Default: 0. Ignored when Custom Stops is filled in.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(15845599832637543)
,p_plugin_id=>wwv_flow_imp.id(15844765216620605)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_static_id=>'mode'
,p_prompt=>'Mode'
,p_apexlang_name=>'mode'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>false
,p_default_value=>'single'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>'Single shows one handle and stores one number (for example 30). Range shows two handles and stores lower:upper (for example 20:80). Default: Single.'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(15846770147639981)
,p_plugin_attribute_id=>wwv_flow_imp.id(15845599832637543)
,p_display_sequence=>20
,p_display_value=>'Range'
,p_return_value=>'range'
,p_apexlang_name=>'range'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(15846385312638802)
,p_plugin_attribute_id=>wwv_flow_imp.id(15845599832637543)
,p_display_sequence=>10
,p_display_value=>'Single'
,p_return_value=>'single'
,p_apexlang_name=>'single'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(15849491899658382)
,p_plugin_id=>wwv_flow_imp.id(15844765216620605)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>6
,p_display_sequence=>60
,p_static_id=>'prefix'
,p_prompt=>'Prefix'
,p_apexlang_name=>'prefix'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_is_translatable=>false
,p_help_text=>'Optional text shown before the selected value and in the handle tooltip, for example $ or Level. Maximum 100 characters.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(15848444942650416)
,p_plugin_id=>wwv_flow_imp.id(15844765216620605)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_static_id=>'step'
,p_prompt=>'Step'
,p_apexlang_name=>'step'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'10'
,p_is_translatable=>false
,p_help_text=>'Distance between two neighbouring stops. Must be greater than 0 and must divide (Maximum - Minimum) exactly. At most 1001 stops are allowed. Example: Minimum 0, Maximum 100, Step 10 gives 11 stops. Default: 10. Ignored when Custom Stops is filled in.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(15849915109660811)
,p_plugin_id=>wwv_flow_imp.id(15844765216620605)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>7
,p_display_sequence=>70
,p_static_id=>'suffix'
,p_prompt=>'Suffix'
,p_apexlang_name=>'suffix'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_is_translatable=>false
,p_help_text=>'Optional text shown after the selected value and in the handle tooltip, for example %, kg or points. Maximum 100 characters.'
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A204D61676E657420536C6964657220302E312E30207C204D49542E20416C6C2072756C6573206172652073636F70656420746F202E6D732D736C696465722E202A2F0D0A2E6D732D736C696465727B626F726465723A31707820736F6C6964207661';
wwv_flow_imp.g_varchar2_table(2) := '72282D2D6D732D616363656E74293B626F726465722D7261646975733A313070783B2D2D6D732D616363656E743A233732353565373B2D2D6D732D747261636B3A236536653865663B2D2D6D732D746578743A233230323433623B2D2D6D732D6D757465';
wwv_flow_imp.g_varchar2_table(3) := '643A233663373238343B626F782D73697A696E673A626F726465722D626F783B6D696E2D77696474683A303B77696474683A313030253B70616464696E673A387078203234707820313270783B636F6C6F723A766172282D2D6D732D74657874293B666F';
wwv_flow_imp.g_varchar2_table(4) := '6E743A696E68657269747D0D0A2E6D732D736C69646572202A7B626F782D73697A696E673A626F726465722D626F787D0D0A2E6D732D736C69646572202E6D732D73756D6D6172797B646973706C61793A666C65783B616C69676E2D6974656D733A6365';
wwv_flow_imp.g_varchar2_table(5) := '6E7465723B6A7573746966792D636F6E74656E743A73706163652D6265747765656E3B6D696E2D6865696768743A343070783B6761703A313270783B6D617267696E2D626F74746F6D3A313270787D0D0A2E6D732D736C69646572202E6D732D73656C65';
wwv_flow_imp.g_varchar2_table(6) := '6374696F6E7B636F6C6F723A766172282D2D6D732D616363656E74293B666F6E742D73697A653A323270783B666F6E742D7765696768743A3730303B666F6E742D76617269616E742D6E756D657269633A746162756C61722D6E756D733B6F766572666C';
wwv_flow_imp.g_varchar2_table(7) := '6F772D777261703A616E7977686572657D0D0A2E6D732D736C69646572202E6D732D636C6561727B626F726465723A303B6261636B67726F756E643A7472616E73706172656E743B666F6E743A696E68657269743B666F6E742D73697A653A313270783B';
wwv_flow_imp.g_varchar2_table(8) := '636F6C6F723A766172282D2D6D732D6D75746564293B70616464696E673A3870783B637572736F723A706F696E7465723B626F726465722D7261646975733A3670787D0D0A2E6D732D736C69646572202E6D732D636C6561723A686F7665727B6261636B';
wwv_flow_imp.g_varchar2_table(9) := '67726F756E643A766172282D2D6D732D747261636B297D0D0A2E6D732D736C69646572202E6D732D636C6561723A64697361626C65647B6F7061636974793A2E343B637572736F723A64656661756C747D0D0A2E6D732D736C69646572202E6D732D7261';
wwv_flow_imp.g_varchar2_table(10) := '696C7B706F736974696F6E3A72656C61746976653B6865696768743A373670783B746F7563682D616374696F6E3A6E6F6E653B637572736F723A706F696E7465723B757365722D73656C6563743A6E6F6E657D0D0A2E6D732D736C69646572202E6D732D';
wwv_flow_imp.g_varchar2_table(11) := '747261636B7B706F736974696F6E3A6162736F6C7574653B746F703A323470783B696E7365742D696E6C696E653A303B6865696768743A3870783B626F726465722D7261646975733A31303070783B6261636B67726F756E643A766172282D2D6D732D74';
wwv_flow_imp.g_varchar2_table(12) := '7261636B293B6F766572666C6F773A68696464656E7D0D0A2E6D732D736C69646572202E6D732D66696C6C7B706F736974696F6E3A6162736F6C7574653B746F703A303B6865696768743A313030253B6261636B67726F756E643A766172282D2D6D732D';
wwv_flow_imp.g_varchar2_table(13) := '616363656E74293B626F726465722D7261646975733A31303070783B7472616E736974696F6E3A7769647468202E35732063756269632D62657A696572282E33342C312E35362C2E36342C31292C696E7365742D696E6C696E652D7374617274202E3573';
wwv_flow_imp.g_varchar2_table(14) := '2063756269632D62657A696572282E33342C312E35362C2E36342C31297D0D0A2E6D732D736C69646572202E6D732D68616E646C657B706F736974696F6E3A6162736F6C7574653B746F703A3670783B77696474683A343470783B6865696768743A3434';
wwv_flow_imp.g_varchar2_table(15) := '70783B6D617267696E2D696E6C696E652D73746172743A2D323270783B70616464696E673A303B626F726465723A303B626F726465722D7261646975733A3530253B6261636B67726F756E643A7472616E73706172656E743B7A2D696E6465783A323B63';
wwv_flow_imp.g_varchar2_table(16) := '7572736F723A677261623B746F7563682D616374696F6E3A6E6F6E653B646973706C61793A677269643B706C6163652D6974656D733A63656E7465723B7472616E736974696F6E3A696E7365742D696E6C696E652D7374617274202E3573206375626963';
wwv_flow_imp.g_varchar2_table(17) := '2D62657A696572282E33342C312E35362C2E36342C31293B6F75746C696E652D6F66667365743A307D0D0A2E6D732D736C69646572202E6D732D68616E646C653A3A6265666F72657B636F6E74656E743A27273B706F736974696F6E3A6162736F6C7574';
wwv_flow_imp.g_varchar2_table(18) := '653B77696474683A323870783B6865696768743A323870783B626F726465723A33707820736F6C696420766172282D2D6D732D616363656E74293B6261636B67726F756E643A236666663B626F726465722D7261646975733A3530253B626F782D736861';
wwv_flow_imp.g_varchar2_table(19) := '646F773A302033707820397078202331623137333432393B7472616E736974696F6E3A626F782D736861646F77203132306D732C7472616E73666F726D202E3335732063756269632D62657A696572282E33342C312E35362C2E36342C31297D0D0A2E6D';
wwv_flow_imp.g_varchar2_table(20) := '732D736C69646572202E6D732D677269707B706F736974696F6E3A72656C61746976653B77696474683A3670783B6865696768743A3670783B6261636B67726F756E643A766172282D2D6D732D616363656E74293B626F726465722D7261646975733A35';
wwv_flow_imp.g_varchar2_table(21) := '30257D0D0A2E6D732D736C696465722E6D732D6472616767696E67202E6D732D68616E646C653A3A6265666F72657B7472616E73666F726D3A7363616C6528312E3138297D0D0A2E6D732D736C69646572202E6D732D68616E646C653A686F7665723A3A';
wwv_flow_imp.g_varchar2_table(22) := '6265666F72652C2E6D732D736C69646572202E6D732D68616E646C653A666F6375732D76697369626C653A3A6265666F72657B626F782D736861646F773A30203020302036707820636F6C6F722D6D697828696E20737267622C766172282D2D6D732D61';
wwv_flow_imp.g_varchar2_table(23) := '6363656E7429203135252C7472616E73706172656E74292C302033707820397078202331623137333432393B7472616E73666F726D3A7363616C6528312E3036297D0D0A2E6D732D736C69646572202E6D732D68616E646C653A666F6375732D76697369';
wwv_flow_imp.g_varchar2_table(24) := '626C652C2E6D732D736C69646572202E6D732D636C6561723A666F6375732D76697369626C657B6F75746C696E653A32707820736F6C696420766172282D2D6D732D616363656E74297D0D0A2E6D732D736C69646572202E6D732D7469636B7B706F7369';
wwv_flow_imp.g_varchar2_table(25) := '74696F6E3A6162736F6C7574653B746F703A323570783B646973706C61793A666C65783B616C69676E2D6974656D733A63656E7465723B666C65782D646972656374696F6E3A636F6C756D6E3B77696474683A303B706F696E7465722D6576656E74733A';
wwv_flow_imp.g_varchar2_table(26) := '6E6F6E657D0D0A2E6D732D736C69646572202E6D732D646F747B646973706C61793A626C6F636B3B666C65782D736872696E6B3A303B77696474683A3670783B6865696768743A3670783B6261636B67726F756E643A236165623363343B626F72646572';
wwv_flow_imp.g_varchar2_table(27) := '2D7261646975733A3530253B7A2D696E6465783A317D0D0A2E6D732D736C69646572202E6D732D696E2D72616E6765202E6D732D646F747B6261636B67726F756E643A636F6C6F722D6D697828696E20737267622C766172282D2D6D732D616363656E74';
wwv_flow_imp.g_varchar2_table(28) := '29203435252C7768697465297D0D0A2E6D732D736C69646572202E6D732D7469636B2D6C6162656C7B6D617267696E2D746F703A323470783B636F6C6F723A766172282D2D6D732D6D75746564293B666F6E742D73697A653A313270783B77686974652D';
wwv_flow_imp.g_varchar2_table(29) := '73706163653A6E6F777261703B666F6E742D76617269616E742D6E756D657269633A746162756C61722D6E756D737D0D0A2E6D732D736C696465722E6D732D656D707479202E6D732D66696C6C7B6F7061636974793A307D0D0A2E6D732D736C69646572';
wwv_flow_imp.g_varchar2_table(30) := '2E6D732D656D707479202E6D732D73656C656374696F6E7B666F6E742D73697A653A313670783B636F6C6F723A766172282D2D6D732D6D75746564293B666F6E742D7765696768743A3430307D0D0A2E6D732D736C696465722E6D732D656D707479202E';
wwv_flow_imp.g_varchar2_table(31) := '6D732D68616E646C653A3A6265666F72657B626F726465722D7374796C653A6461736865647D0D0A2E6D732D736C696465722E6D732D64697361626C65647B6F7061636974793A2E357D0D0A2E6D732D736C696465722E6D732D64697361626C6564202E';
wwv_flow_imp.g_varchar2_table(32) := '6D732D7261696C2C2E6D732D736C696465722E6D732D64697361626C6564202E6D732D68616E646C657B637572736F723A64656661756C747D0D0A2E6D732D736C696465722E6D732D6472616767696E67202E6D732D68616E646C657B637572736F723A';
wwv_flow_imp.g_varchar2_table(33) := '6772616262696E677D0D0A2E6D732D736C696465722E6D732D6472616767696E67202E6D732D66696C6C2C2E6D732D736C696465722E6D732D6472616767696E67202E6D732D68616E646C657B7472616E736974696F6E2D6475726174696F6E3A2E3373';
wwv_flow_imp.g_varchar2_table(34) := '7D0D0A406D65646961286D61782D77696474683A3438307078297B2E6D732D736C696465727B70616464696E672D696E6C696E653A323070787D2E6D732D736C69646572202E6D732D7469636B2D6C6162656C7B666F6E742D73697A653A313070787D2E';
wwv_flow_imp.g_varchar2_table(35) := '6D732D736C69646572202E6D732D73656C656374696F6E7B666F6E742D73697A653A323070787D7D0D0A406D6564696128707265666572732D726564756365642D6D6F74696F6E3A726564756365297B2E6D732D736C69646572202A2C2E6D732D736C69';
wwv_flow_imp.g_varchar2_table(36) := '646572202A3A3A6265666F72657B7472616E736974696F6E3A6E6F6E6521696D706F7274616E747D7D0D0A406D6564696128666F726365642D636F6C6F72733A616374697665297B2E6D732D736C69646572202E6D732D747261636B7B626F726465723A';
wwv_flow_imp.g_varchar2_table(37) := '31707820736F6C69642043616E766173546578747D2E6D732D736C69646572202E6D732D66696C6C7B6261636B67726F756E643A486967686C696768747D2E6D732D736C69646572202E6D732D68616E646C653A3A6265666F72657B626F726465722D63';
wwv_flow_imp.g_varchar2_table(38) := '6F6C6F723A427574746F6E546578747D2E6D732D736C69646572202E6D732D677269707B6261636B67726F756E643A427574746F6E546578747D7D0D0A0D0A2E6D732D736C69646572202E6D732D627562626C657B706F736974696F6E3A6162736F6C75';
wwv_flow_imp.g_varchar2_table(39) := '74653B626F74746F6D3A343770783B6C6566743A3530253B7472616E73666F726D3A7472616E736C61746558282D35302529207472616E736C6174655928337078293B6261636B67726F756E643A766172282D2D6D732D616363656E74293B636F6C6F72';
wwv_flow_imp.g_varchar2_table(40) := '3A236666663B626F726465722D7261646975733A3770783B70616464696E673A367078203970783B77686974652D73706163653A6E6F777261703B666F6E743A36303020313270782F312E322073797374656D2D75693B706F696E7465722D6576656E74';
wwv_flow_imp.g_varchar2_table(41) := '733A6E6F6E653B6F7061636974793A303B7472616E736974696F6E3A6F706163697479203130306D732C7472616E73666F726D203130306D737D0D0A2E6D732D736C69646572202E6D732D68616E646C653A686F766572202E6D732D627562626C652C2E';
wwv_flow_imp.g_varchar2_table(42) := '6D732D736C69646572202E6D732D68616E646C653A666F6375732D76697369626C65202E6D732D627562626C652C2E6D732D736C696465722E6D732D6472616767696E67202E6D732D68616E646C653A666F637573202E6D732D627562626C657B6F7061';
wwv_flow_imp.g_varchar2_table(43) := '636974793A313B7472616E73666F726D3A7472616E736C61746558282D35302529207472616E736C617465592830297D0D0A2E6D732D736C696465722E6D732D61742D65646765202E6D732D68616E646C652C0D0A2E6D732D736C696465722E6D732D61';
wwv_flow_imp.g_varchar2_table(44) := '742D65646765202E6D732D66696C6C7B7472616E736974696F6E2D74696D696E672D66756E6374696F6E3A63756269632D62657A696572282E32352C2E392C2E33352C31297D0D0A2E6D732D6C6162656C2D626F787B77696474683A313030253B746578';
wwv_flow_imp.g_varchar2_table(45) := '742D616C69676E3A63656E7465727D0D0A2E6D732D6C6162656C2D626F78202E742D466F726D2D6C6162656C7B646973706C61793A626C6F636B3B666F6E742D7765696768743A3730303B746578742D616C69676E3A63656E7465727D';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(15853531391684112)
,p_plugin_id=>wwv_flow_imp.id(15844765216620605)
,p_file_name=>'apex-magnet-slider.css'
,p_mime_type=>'text/css'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A204D61676E657420536C6964657220302E312E30207C204D4954202A2F0D0A2866756E6374696F6E2028676C6F62616C29207B0D0A20202775736520737472696374273B0D0A2020636F6E7374205343414C45203D20313030303030303B0D0A2020';
wwv_flow_imp.g_varchar2_table(2) := '636F6E7374204E554D424552203D202F5E2D3F283F3A307C5B312D395D5C642A29283F3A5C2E5C647B312C367D293F242F3B0D0A202066756E6374696F6E206E756D6265722876616C756529207B0D0A20202020636F6E73742073203D20537472696E67';
wwv_flow_imp.g_varchar2_table(3) := '2876616C7565292E7472696D28293B0D0A2020202069662028214E554D4245522E7465737428732929207468726F77206E6577204572726F72282755736520706C61696E206E756D62657273207769746820757020746F203620646563696D616C20706C';
wwv_flow_imp.g_varchar2_table(4) := '616365732E27293B0D0A20202020636F6E7374206E203D204E756D6265722873293B0D0A2020202069662028214E756D6265722E697346696E697465286E29207C7C204D6174682E616273286E29203E2031653929207468726F77206E6577204572726F';
wwv_flow_imp.g_varchar2_table(5) := '7228274E756D62657273206D757374206265206265747765656E202D312062696C6C696F6E20616E6420312062696C6C696F6E2E27293B0D0A2020202072657475726E204D6174682E726F756E64286E202A205343414C45293B0D0A20207D0D0A202066';
wwv_flow_imp.g_varchar2_table(6) := '756E6374696F6E20646F6D61696E28636F6E66696729207B0D0A202020206C65742076616C7565733B0D0A2020202069662028636F6E6669672E76616C75657320213D206E756C6C20262620636F6E6669672E76616C75657320213D3D20272729207B0D';
wwv_flow_imp.g_varchar2_table(7) := '0A202020202020636F6E737420726177203D2041727261792E6973417272617928636F6E6669672E76616C75657329203F20636F6E6669672E76616C756573203A20537472696E6728636F6E6669672E76616C756573292E73706C697428272C27293B0D';
wwv_flow_imp.g_varchar2_table(8) := '0A20202020202076616C756573203D207261772E6D6170286E756D626572293B0D0A202020207D20656C7365207B0D0A202020202020636F6E7374206D696E203D206E756D62657228636F6E6669672E6D696E203F3F2030292C206D6178203D206E756D';
wwv_flow_imp.g_varchar2_table(9) := '62657228636F6E6669672E6D6178203F3F20313030292C2073746570203D206E756D62657228636F6E6669672E73746570203F3F203130293B0D0A2020202020206966202873746570203C3D2030207C7C206D6178203C3D206D696E207C7C20286D6178';
wwv_flow_imp.g_varchar2_table(10) := '202D206D696E292025207374657020213D3D203029207468726F77206E6577204572726F7228274D6178206D75737420657863656564206D696E20616E6420286D617820E28892206D696E29206D757374206469766964652065786163746C7920627920';
wwv_flow_imp.g_varchar2_table(11) := '737465702E27293B0D0A202020202020636F6E737420636F756E74203D20286D6178202D206D696E29202F2073746570202B20313B0D0A20202020202069662028636F756E74203E203130303129207468726F77206E6577204572726F72282755736520';
wwv_flow_imp.g_varchar2_table(12) := '6174206D6F737420312C3030312073746F70732E27293B0D0A20202020202076616C756573203D2041727261792E66726F6D287B6C656E6774683A20636F756E747D2C20285F2C206929203D3E206D696E202B2069202A2073746570293B0D0A20202020';
wwv_flow_imp.g_varchar2_table(13) := '7D0D0A202020206966202876616C7565732E6C656E677468203C2032207C7C2076616C7565732E6C656E677468203E2031303031207C7C2076616C7565732E736F6D652828762C6929203D3E20692026262076203C3D2076616C7565735B692D315D2929';
wwv_flow_imp.g_varchar2_table(14) := '207B0D0A2020202020207468726F77206E6577204572726F722827537570706C792032E28093312C30303120756E69717565206E756D6265727320696E20696E6372656173696E67206F726465722E27293B0D0A202020207D0D0A202020207265747572';
wwv_flow_imp.g_varchar2_table(15) := '6E2076616C7565732E6D61702876203D3E2076202F205343414C45293B0D0A20207D0D0A2020636C617373204D6F64656C207B0D0A20202020636F6E7374727563746F7228636F6E666967203D207B7D29207B0D0A202020202020746869732E76616C75';
wwv_flow_imp.g_varchar2_table(16) := '6573203D20646F6D61696E28636F6E666967293B0D0A202020202020746869732E72616E6765203D20636F6E6669672E6D6F6465203D3D3D202772616E6765273B0D0A20202020202069662028636F6E6669672E6D6F646520262620215B2773696E676C';
wwv_flow_imp.g_varchar2_table(17) := '65272C2772616E6765275D2E696E636C7564657328636F6E6669672E6D6F64652929207468726F77206E6577204572726F7228274D6F6465206D7573742062652073696E676C65206F722072616E67652E27293B0D0A202020202020746869732E696E64';
wwv_flow_imp.g_varchar2_table(18) := '69636573203D20746869732E72616E6765203F205B302C20746869732E76616C7565732E6C656E677468202D20315D203A205B305D3B0D0A202020202020746869732E656D707479203D20747275653B0D0A202020202020747279207B20746869732E73';
wwv_flow_imp.g_varchar2_table(19) := '657428636F6E6669672E76616C7565203F3F202727293B207D20636174636820286529207B20746869732E736574282727293B207D0D0A202020207D0D0A202020207365742876616C756529207B0D0A2020202020206966202876616C7565203D3D3D20';
wwv_flow_imp.g_varchar2_table(20) := '2727207C7C2076616C7565203D3D206E756C6C29207B0D0A202020202020746869732E656D707479203D20747275653B0D0A202020202020746869732E696E6469636573203D20746869732E72616E6765203F205B302C20746869732E76616C7565732E';
wwv_flow_imp.g_varchar2_table(21) := '6C656E677468202D20315D203A205B305D3B0D0A20202020202072657475726E3B0D0A2020202020207D0D0A202020202020636F6E7374207061727473203D20537472696E672876616C7565292E73706C697428273A27293B0D0A202020202020696620';
wwv_flow_imp.g_varchar2_table(22) := '2870617274732E6C656E67746820213D3D2028746869732E72616E6765203F2032203A20312929207468726F77206E6577204572726F7228746869732E72616E6765203F2027557365206C6F7765723A75707065722E27203A2027557365206F6E65206E';
wwv_flow_imp.g_varchar2_table(23) := '756D6265722E27293B0D0A202020202020636F6E7374206E657874203D2070617274732E6D61702870203D3E20746869732E76616C7565732E696E6465784F66286E756D626572287029202F205343414C4529293B0D0A202020202020696620286E6578';
wwv_flow_imp.g_varchar2_table(24) := '742E736F6D652869203D3E2069203C203029207C7C2028746869732E72616E6765202626206E6578745B305D203E206E6578745B315D2929207468726F77206E6577204572726F72282743686F6F736520616C6C6F776564206E756D6265727320696E20';
wwv_flow_imp.g_varchar2_table(25) := '617363656E64696E67206F726465722E27293B0D0A202020202020746869732E696E6469636573203D206E6578743B20746869732E656D707479203D2066616C73653B0D0A202020207D0D0A202020206D6F76652868616E646C652C20696E6465782920';
wwv_flow_imp.g_varchar2_table(26) := '7B0D0A202020202020636F6E7374206C6F77203D20746869732E72616E67652026262068616E646C65203D3D3D2031203F20746869732E696E64696365735B305D203A20303B0D0A202020202020636F6E73742068696768203D20746869732E72616E67';
wwv_flow_imp.g_varchar2_table(27) := '652026262068616E646C65203D3D3D2030203F20746869732E696E64696365735B315D203A20746869732E76616C7565732E6C656E677468202D20313B0D0A202020202020746869732E696E64696365735B68616E646C655D203D204D6174682E6D6178';
wwv_flow_imp.g_varchar2_table(28) := '286C6F772C204D6174682E6D696E28686967682C204D6174682E726F756E6428696E6465782929293B0D0A202020202020746869732E656D707479203D2066616C73653B0D0A202020207D0D0A202020206765742829207B2072657475726E2074686973';
wwv_flow_imp.g_varchar2_table(29) := '2E656D707479203F202727203A20746869732E696E64696365732E6D61702869203D3E20746869732E76616C7565735B695D292E6A6F696E28273A27293B207D0D0A20207D0D0A202066756E6374696F6E206D6F756E7428696E7075744F7249642C2063';
wwv_flow_imp.g_varchar2_table(30) := '6F6E666967203D207B7D29207B0D0A20202020636F6E737420696E707574203D20747970656F6620696E7075744F724964203D3D3D2027737472696E6727203F20646F63756D656E742E676574456C656D656E744279496428696E7075744F7249642920';
wwv_flow_imp.g_varchar2_table(31) := '3A20696E7075744F7249643B0D0A202020206966202821696E70757429207468726F77206E6577204572726F7228274D61676E657420536C6964657220696E707574206E6F7420666F756E642E27293B0D0A2020202069662028696E7075742E6D61676E';
wwv_flow_imp.g_varchar2_table(32) := '6574536C696465722920696E7075742E6D61676E6574536C696465722E64657374726F7928293B0D0A20202020636F6E7374206D6F64656C203D206E6577204D6F64656C287B2E2E2E636F6E6669672C2076616C75653A20696E7075742E76616C75657D';
wwv_flow_imp.g_varchar2_table(33) := '293B0D0A20202020636F6E737420696E697469616C203D206D6F64656C2E67657428293B0D0A20202020636F6E7374206F726967696E616C54797065203D20696E7075742E747970653B0D0A20202020696E7075742E74797065203D202768696464656E';
wwv_flow_imp.g_varchar2_table(34) := '273B0D0A202020206C65742064697361626C6564203D202121636F6E6669672E64697361626C65642C20616374697665203D206E756C6C2C20737461727456616C7565203D2027272C206C61737448616E646C65203D20303B0D0A20202020636F6E7374';
wwv_flow_imp.g_varchar2_table(35) := '206C697374656E657273203D205B5D3B0D0A2020202066756E6374696F6E206F6E28656C2C206576656E742C20666E29207B20656C2E6164644576656E744C697374656E6572286576656E742C20666E293B206C697374656E6572732E70757368282829';
wwv_flow_imp.g_varchar2_table(36) := '203D3E20656C2E72656D6F76654576656E744C697374656E6572286576656E742C20666E29293B207D0D0A2020202066756E6374696F6E20656C287461672C20636C732C207465787429207B20636F6E73742078203D20646F63756D656E742E63726561';
wwv_flow_imp.g_varchar2_table(37) := '7465456C656D656E7428746167293B20782E636C6173734E616D65203D20636C733B20696620287465787420213D206E756C6C2920782E74657874436F6E74656E74203D20746578743B2072657475726E20783B207D0D0A20202020636F6E737420726F';
wwv_flow_imp.g_varchar2_table(38) := '6F74203D20656C2827646976272C276D732D736C6964657227293B0D0A2020202069662028636F6E6669672E616363656E74202626202F5E235B302D39612D665D7B367D242F692E7465737428636F6E6669672E616363656E74292920726F6F742E7374';
wwv_flow_imp.g_varchar2_table(39) := '796C652E73657450726F706572747928272D2D6D732D616363656E74272C636F6E6669672E616363656E74293B0D0A20202020636F6E73742073756D6D617279203D20656C2827646976272C276D732D73756D6D61727927293B0D0A20202020636F6E73';
wwv_flow_imp.g_varchar2_table(40) := '7420737461747573203D20656C28277370616E272C276D732D73656C656374696F6E27293B0D0A20202020636F6E737420636C656172203D20656C2827627574746F6E272C276D732D636C656172272C636F6E6669672E636C6561724C6162656C207C7C';
wwv_flow_imp.g_varchar2_table(41) := '2027436C65617227293B20636C6561722E74797065203D2027627574746F6E273B0D0A20202020636C6561722E7365744174747269627574652827617269612D6C6162656C272C2028636F6E6669672E636C6561724C6162656C207C7C2027436C656172';
wwv_flow_imp.g_varchar2_table(42) := '2729202B20272027202B2028636F6E6669672E6C6162656C207C7C20696E7075742E696429293B0D0A2020202073756D6D6172792E617070656E6428737461747573293B0D0A2020202069662028636F6E6669672E616C6C6F77436C65617220213D3D20';
wwv_flow_imp.g_varchar2_table(43) := '66616C7365292073756D6D6172792E617070656E6428636C656172293B0D0A20202020636F6E7374207261696C203D20656C2827646976272C276D732D7261696C27292C20747261636B203D20656C2827646976272C276D732D747261636B27292C2066';
wwv_flow_imp.g_varchar2_table(44) := '696C6C203D20656C2827646976272C276D732D66696C6C27292C207469636B73203D20656C2827646976272C276D732D7469636B7327293B0D0A20202020747261636B2E617070656E642866696C6C293B207261696C2E617070656E6428747261636B2C';
wwv_flow_imp.g_varchar2_table(45) := '7469636B73293B0D0A20202020636F6E737420666F726D6174203D206E203D3E2028636F6E6669672E707265666978207C7C20272729202B20537472696E67286E29202B2028636F6E6669672E737566666978207C7C202727293B0D0A20202020636F6E';
wwv_flow_imp.g_varchar2_table(46) := '73742068616E646C6573203D206D6F64656C2E696E64696365732E6D617028285F2C6929203D3E207B0D0A202020202020636F6E73742068203D20656C2827627574746F6E272C276D732D68616E646C6527293B20682E74797065203D2027627574746F';
wwv_flow_imp.g_varchar2_table(47) := '6E273B20682E6964203D20696E7075742E6964202B20275F48414E444C455F27202B20693B0D0A202020202020682E7365744174747269627574652827726F6C65272C27736C6964657227293B20682E7365744174747269627574652827617269612D6F';
wwv_flow_imp.g_varchar2_table(48) := '7269656E746174696F6E272C27686F72697A6F6E74616C27293B0D0A202020202020682E7365744174747269627574652827617269612D6C6162656C272C28636F6E6669672E6C6162656C207C7C20696E7075742E696429202B20286D6F64656C2E7261';
wwv_flow_imp.g_varchar2_table(49) := '6E6765203F202869203F202720E280942075707065722076616C756527203A202720E28094206C6F7765722076616C75652729203A20272729293B0D0A202020202020636F6E7374206465736372697074696F6E203D20696E7075742E67657441747472';
wwv_flow_imp.g_varchar2_table(50) := '69627574652827617269612D646573637269626564627927293B0D0A202020202020696620286465736372697074696F6E2920682E7365744174747269627574652827617269612D6465736372696265646279272C6465736372697074696F6E293B0D0A';
wwv_flow_imp.g_varchar2_table(51) := '20202020202069662028636F6E6669672E72657175697265642920682E7365744174747269627574652827617269612D7265717569726564272C277472756527293B0D0A202020202020682E617070656E6428656C28277370616E272C276D732D677269';
wwv_flow_imp.g_varchar2_table(52) := '7027292C20656C28277370616E272C276D732D627562626C652729293B0D0A202020202020682E6C6173744368696C642E7365744174747269627574652827617269612D68696464656E272C277472756527293B0D0A2020202020207261696C2E617070';
wwv_flow_imp.g_varchar2_table(53) := '656E642868293B2072657475726E20683B0D0A202020207D293B0D0A20202020636F6E7374206D61726B73203D205B5D3B0D0A202020202F2F205468696E2064656E736520646F6D61696E7320746F2061207265616461626C6520736574206F66207669';
wwv_flow_imp.g_varchar2_table(54) := '7375616C207469636B733B2065766572792073746F702072656D61696E732073656C65637461626C652E0D0A20202020636F6E737420636F756E74203D204D6174682E6D696E286D6F64656C2E76616C7565732E6C656E6774682C204D6174682E6D6178';
wwv_flow_imp.g_varchar2_table(55) := '28322C4D6174682E6D696E2832312C4E756D62657228636F6E6669672E6D61785469636B7329207C7C2031312929293B0D0A20202020636F6E7374206D61726B496E6469636573203D205B2E2E2E6E6577205365742841727261792E66726F6D287B6C65';
wwv_flow_imp.g_varchar2_table(56) := '6E6774683A636F756E747D2C285F2C69293D3E4D6174682E726F756E6428692A286D6F64656C2E76616C7565732E6C656E6774682D31292F28636F756E742D31292929295D3B0D0A202020206D61726B496E64696365732E666F724561636828693D3E7B';
wwv_flow_imp.g_varchar2_table(57) := '0D0A202020202020636F6E73742074203D20656C28277370616E272C276D732D7469636B27293B20742E7374796C652E696E736574496E6C696E655374617274203D20692F286D6F64656C2E76616C7565732E6C656E6774682D31292A3130302B272527';
wwv_flow_imp.g_varchar2_table(58) := '3B0D0A202020202020742E617070656E6428656C28277370616E272C276D732D646F7427292C656C28277370616E272C276D732D7469636B2D6C6162656C272C537472696E67286D6F64656C2E76616C7565735B695D2929293B7469636B732E61707065';
wwv_flow_imp.g_varchar2_table(59) := '6E642874293B6D61726B732E70757368285B692C745D293B0D0A202020207D293B0D0A20202020726F6F742E617070656E642873756D6D6172792C7261696C293B20696E7075742E616674657228726F6F74293B0D0A20202020636F6E7374206C616265';
wwv_flow_imp.g_varchar2_table(60) := '6C426F78203D20696E7075742E636C6F7365737428272E742D466F726D2D6669656C64436F6E7461696E657227293F2E717565727953656C6563746F7228272E742D466F726D2D6C6162656C436F6E7461696E657227293B0D0A20202020696620286C61';
wwv_flow_imp.g_varchar2_table(61) := '62656C426F7829206C6162656C426F782E636C6173734C6973742E61646428276D732D6C6162656C2D626F7827293B0D0A20202020636F6E73742072746C203D202829203D3E20676574436F6D70757465645374796C6528726F6F74292E646972656374';
wwv_flow_imp.g_varchar2_table(62) := '696F6E203D3D3D202772746C273B0D0A2020202066756E6374696F6E207061696E742829207B0D0A202020202020696E7075742E76616C7565203D206D6F64656C2E67657428293B20726F6F742E636C6173734C6973742E746F67676C6528276D732D65';
wwv_flow_imp.g_varchar2_table(63) := '6D707479272C6D6F64656C2E656D707479293B20726F6F742E636C6173734C6973742E746F67676C6528276D732D64697361626C6564272C64697361626C6564293B0D0A2020202020207374617475732E74657874436F6E74656E74203D206D6F64656C';
wwv_flow_imp.g_varchar2_table(64) := '2E656D707479203F2028636F6E6669672E656D7074794C6162656C207C7C202743686F6F736520612076616C75652729203A206D6F64656C2E696E64696365732E6D617028693D3E666F726D6174286D6F64656C2E76616C7565735B695D29292E6A6F69';
wwv_flow_imp.g_varchar2_table(65) := '6E282720E280942027293B0D0A202020202020636C6561722E64697361626C6564203D2064697361626C6564207C7C206D6F64656C2E656D7074793B0D0A202020202020726F6F742E636C6173734C6973742E746F67676C6528276D732D61742D656467';
wwv_flow_imp.g_varchar2_table(66) := '65272C206D6F64656C2E696E64696365732E736F6D652869203D3E2069203D3D3D2030207C7C2069203D3D3D206D6F64656C2E76616C7565732E6C656E677468202D203129293B0D0A202020202020636F6E73742061203D206D6F64656C2E72616E6765';
wwv_flow_imp.g_varchar2_table(67) := '203F206D6F64656C2E696E64696365735B305D203A20302C2062203D206D6F64656C2E696E64696365735B6D6F64656C2E696E64696365732E6C656E6774682D315D3B0D0A20202020202066696C6C2E7374796C652E696E736574496E6C696E65537461';
wwv_flow_imp.g_varchar2_table(68) := '7274203D20612F286D6F64656C2E76616C7565732E6C656E6774682D31292A3130302B2725273B2066696C6C2E7374796C652E7769647468203D2028622D61292F286D6F64656C2E76616C7565732E6C656E6774682D31292A3130302B2725273B0D0A20';
wwv_flow_imp.g_varchar2_table(69) := '202020202068616E646C65732E666F72456163682828682C69293D3E7B0D0A2020202020202020682E7374796C652E696E736574496E6C696E655374617274203D206D6F64656C2E696E64696365735B695D2F286D6F64656C2E76616C7565732E6C656E';
wwv_flow_imp.g_varchar2_table(70) := '6774682D31292A3130302B2725273B0D0A2020202020202020682E64697361626C6564203D2064697361626C65643B0D0A2020202020202020682E7365744174747269627574652827617269612D76616C75656D696E272C6D6F64656C2E76616C756573';
wwv_flow_imp.g_varchar2_table(71) := '5B6D6F64656C2E72616E676520262620693D3D3D31203F206D6F64656C2E696E64696365735B305D203A20305D293B0D0A2020202020202020682E7365744174747269627574652827617269612D76616C75656D6178272C6D6F64656C2E76616C756573';
wwv_flow_imp.g_varchar2_table(72) := '5B6D6F64656C2E72616E676520262620693D3D3D30203F206D6F64656C2E696E64696365735B315D203A206D6F64656C2E76616C7565732E6C656E6774682D315D293B0D0A2020202020202020682E7365744174747269627574652827617269612D7661';
wwv_flow_imp.g_varchar2_table(73) := '6C75656E6F77272C6D6F64656C2E76616C7565735B6D6F64656C2E696E64696365735B695D5D293B0D0A2020202020202020682E7365744174747269627574652827617269612D76616C756574657874272C6D6F64656C2E656D707479203F2028636F6E';
wwv_flow_imp.g_varchar2_table(74) := '6669672E656D7074794C6162656C207C7C20274E6F2076616C75652073656C65637465642729203A20666F726D6174286D6F64656C2E76616C7565735B6D6F64656C2E696E64696365735B695D5D29293B0D0A2020202020202020682E7469746C65203D';
wwv_flow_imp.g_varchar2_table(75) := '20666F726D6174286D6F64656C2E76616C7565735B6D6F64656C2E696E64696365735B695D5D293B0D0A2020202020202020682E717565727953656C6563746F7228272E6D732D627562626C6527292E74657874436F6E74656E74203D20682E7469746C';
wwv_flow_imp.g_varchar2_table(76) := '653B0D0A2020202020207D293B0D0A2020202020206D61726B732E666F724561636828285B692C745D293D3E742E636C6173734C6973742E746F67676C6528276D732D696E2D72616E6765272C20216D6F64656C2E656D70747920262620693E3D612026';
wwv_flow_imp.g_varchar2_table(77) := '2620693C3D6229293B0D0A202020207D0D0A2020202066756E6374696F6E20656D6974286E616D6529207B20696E7075742E64697370617463684576656E74286E6577204576656E74286E616D652C7B627562626C65733A747275657D29293B207D0D0A';
wwv_flow_imp.g_varchar2_table(78) := '2020202066756E6374696F6E20636F6D6D6974286265666F726529207B20696620286D6F64656C2E676574282920213D3D206265666F72652920656D697428276368616E676527293B207D0D0A2020202066756E6374696F6E206D6F766528692C20696E';
wwv_flow_imp.g_varchar2_table(79) := '64657829207B20636F6E7374206265666F72653D6D6F64656C2E67657428293B206D6F64656C2E6D6F766528692C696E646578293B207061696E7428293B20696620286265666F7265213D3D6D6F64656C2E67657428292920656D69742827696E707574';
wwv_flow_imp.g_varchar2_table(80) := '27293B207D0D0A2020202066756E6374696F6E20706F696E746572496E646578286529207B20636F6E737420723D7261696C2E676574426F756E64696E67436C69656E745265637428293B206C657420663D4D6174682E6D617828302C4D6174682E6D69';
wwv_flow_imp.g_varchar2_table(81) := '6E28312C28652E636C69656E74582D722E6C656674292F722E776964746829293B2072657475726E202872746C28293F312D663A66292A286D6F64656C2E76616C7565732E6C656E6774682D31293B207D0D0A202020206F6E287261696C2C27706F696E';
wwv_flow_imp.g_varchar2_table(82) := '746572646F776E272C20653D3E7B0D0A2020202020206966202864697361626C6564207C7C2021652E69735072696D617279207C7C20652E627574746F6E213D3D30292072657475726E3B0D0A202020202020636F6E7374206869743D68616E646C6573';
wwv_flow_imp.g_varchar2_table(83) := '2E66696E64496E64657828683D3E683D3D3D652E746172676574207C7C20682E636F6E7461696E7328652E74617267657429293B0D0A202020202020636F6E737420696E6465783D706F696E746572496E6465782865293B0D0A2020202020206C657420';
wwv_flow_imp.g_varchar2_table(84) := '63686F73656E3D6869743B0D0A2020202020206966202863686F73656E3C3029207B0D0A202020202020202069662028216D6F64656C2E72616E6765292063686F73656E3D303B0D0A2020202020202020656C7365207B0D0A2020202020202020202063';
wwv_flow_imp.g_varchar2_table(85) := '6F6E73742064303D4D6174682E61627328696E6465782D6D6F64656C2E696E64696365735B305D292C64313D4D6174682E61627328696E6465782D6D6F64656C2E696E64696365735B315D293B0D0A2020202020202020202063686F73656E3D64303D3D';
wwv_flow_imp.g_varchar2_table(86) := '3D6431203F2028696E6465783C6D6F64656C2E696E64696365735B305D3F303A696E6465783E6D6F64656C2E696E64696365735B315D3F313A6C61737448616E646C6529203A2064303C64313F303A313B0D0A20202020202020207D0D0A202020202020';
wwv_flow_imp.g_varchar2_table(87) := '7D0D0A2020202020206163746976653D7B68616E646C653A63686F73656E2C69643A652E706F696E74657249647D3B206C61737448616E646C653D63686F73656E3B20737461727456616C75653D6D6F64656C2E67657428293B0D0A202020202020726F';
wwv_flow_imp.g_varchar2_table(88) := '6F742E636C6173734C6973742E61646428276D732D6472616767696E6727293B2068616E646C65735B63686F73656E5D2E666F63757328293B207261696C2E736574506F696E7465724361707475726528652E706F696E7465724964293B0D0A20202020';
wwv_flow_imp.g_varchar2_table(89) := '20206D6F76652863686F73656E2C696E646578293B20652E70726576656E7444656661756C7428293B0D0A202020207D293B0D0A202020206F6E287261696C2C27706F696E7465726D6F7665272C653D3E7B696628616374697665202626206163746976';
wwv_flow_imp.g_varchar2_table(90) := '652E69643D3D3D652E706F696E746572496429206D6F7665286163746976652E68616E646C652C706F696E746572496E646578286529293B7D293B0D0A2020202066756E6374696F6E2066696E697368286529207B2069662821616374697665207C7C20';
wwv_flow_imp.g_varchar2_table(91) := '6163746976652E6964213D3D652E706F696E74657249642972657475726E3B206163746976653D6E756C6C3B20726F6F742E636C6173734C6973742E72656D6F766528276D732D6472616767696E6727293B20636F6D6D697428737461727456616C7565';
wwv_flow_imp.g_varchar2_table(92) := '293B207D0D0A202020206F6E287261696C2C27706F696E7465727570272C66696E697368293B6F6E287261696C2C27706F696E74657263616E63656C272C66696E697368293B6F6E287261696C2C276C6F7374706F696E74657263617074757265272C66';
wwv_flow_imp.g_varchar2_table(93) := '696E697368293B0D0A2020202068616E646C65732E666F72456163682828682C69293D3E7B0D0A2020202020206F6E28682C27666F637573272C28293D3E7B6C61737448616E646C653D693B2068616E646C65732E666F724561636828783D3E782E7374';
wwv_flow_imp.g_varchar2_table(94) := '796C652E7A496E6465783D273227293B682E7374796C652E7A496E6465783D2733273B7D293B0D0A2020202020206F6E28682C276B6579646F776E272C653D3E7B0D0A202020202020202069662864697361626C65642972657475726E3B0D0A20202020';
wwv_flow_imp.g_varchar2_table(95) := '202020206C6574206E3D6D6F64656C2E696E64696365735B695D3B0D0A202020202020202073776974636828652E6B6579297B0D0A202020202020202020206361736520274172726F775269676874273A6E2B3D72746C28293F2D313A313B627265616B';
wwv_flow_imp.g_varchar2_table(96) := '3B0D0A202020202020202020206361736520274172726F774C656674273A6E2B3D72746C28293F313A2D313B627265616B3B0D0A202020202020202020206361736520274172726F775570273A6E2B2B3B627265616B3B6361736520274172726F77446F';
wwv_flow_imp.g_varchar2_table(97) := '776E273A6E2D2D3B627265616B3B0D0A20202020202020202020636173652027506167655570273A6E2B3D31303B627265616B3B63617365202750616765446F776E273A6E2D3D31303B627265616B3B0D0A20202020202020202020636173652027486F';
wwv_flow_imp.g_varchar2_table(98) := '6D65273A6E3D303B627265616B3B636173652027456E64273A6E3D6D6F64656C2E76616C7565732E6C656E6774682D313B627265616B3B0D0A2020202020202020202064656661756C743A72657475726E3B0D0A20202020202020207D0D0A2020202020';
wwv_flow_imp.g_varchar2_table(99) := '202020652E70726576656E7444656661756C7428293B20636F6E7374206265666F72653D6D6F64656C2E67657428293B6D6F766528692C6E293B636F6D6D6974286265666F7265293B0D0A2020202020207D293B0D0A202020207D293B0D0A202020206F';
wwv_flow_imp.g_varchar2_table(100) := '6E28636C6561722C27636C69636B272C28293D3E7B0D0A2020202020202020636F6E7374206265666F72653D6D6F64656C2E67657428293B0D0A2020202020202020696628646F63756D656E742E616374697665456C656D656E742920646F63756D656E';
wwv_flow_imp.g_varchar2_table(101) := '742E616374697665456C656D656E742E626C757228293B0D0A20202020202020206D6F64656C2E736574282727293B7061696E7428293B656D69742827696E70757427293B636F6D6D6974286265666F7265293B0D0A202020207D293B0D0A2020202069';
wwv_flow_imp.g_varchar2_table(102) := '6628696E7075742E666F726D29206F6E28696E7075742E666F726D2C277265736574272C28293D3E71756575654D6963726F7461736B2828293D3E7B6D6F64656C2E73657428696E697469616C293B7061696E7428293B7D29293B0D0A20202020636F6E';
wwv_flow_imp.g_varchar2_table(103) := '7374206170693D7B0D0A20202020202067657456616C75653A28293D3E6D6F64656C2E67657428292C0D0A20202020202073657456616C75652876616C7565297B6D6F64656C2E7365742876616C7565293B7061696E7428293B7D2C0D0A202020202020';
wwv_flow_imp.g_varchar2_table(104) := '64697361626C6528297B64697361626C65643D747275653B7061696E7428293B7D2C656E61626C6528297B64697361626C65643D66616C73653B7061696E7428293B7D2C697344697361626C65643A28293D3E64697361626C65642C0D0A202020202020';
wwv_flow_imp.g_varchar2_table(105) := '666F63757328297B68616E646C65735B305D2E666F63757328293B7D2C0D0A20202020202064657374726F7928297B6C697374656E6572732E666F724561636828666E3D3E666E2829293B696620286C6162656C426F7829206C6162656C426F782E636C';
wwv_flow_imp.g_varchar2_table(106) := '6173734C6973742E72656D6F766528276D732D6C6162656C2D626F7827293B726F6F742E72656D6F766528293B696E7075742E747970653D6F726967696E616C547970653B64656C65746520696E7075742E6D61676E6574536C696465723B7D2C0D0A20';
wwv_flow_imp.g_varchar2_table(107) := '20202020206D6F64656C2C726F6F740D0A202020207D3B0D0A20202020696E7075742E6D61676E6574536C696465723D6170693B0D0A20202020696628676C6F62616C2E6170657820262620676C6F62616C2E617065782E6974656D2026262074797065';
wwv_flow_imp.g_varchar2_table(108) := '6F6620676C6F62616C2E617065782E6974656D2E6372656174653D3D3D2766756E6374696F6E2729207B0D0A202020202020676C6F62616C2E617065782E6974656D2E63726561746528696E7075742E69642C7B0D0A20202020202020206974656D5F74';
wwv_flow_imp.g_varchar2_table(109) := '7970653A274D41474E45545F534C49444552272C2067657456616C75653A6170692E67657456616C75652C73657456616C75653A6170692E73657456616C75652C0D0A202020202020202064697361626C653A6170692E64697361626C652C656E61626C';
wwv_flow_imp.g_varchar2_table(110) := '653A6170692E656E61626C652C697344697361626C65643A6170692E697344697361626C65642C0D0A202020202020202069734368616E6765643A28293D3E6D6F64656C2E6765742829213D3D696E697469616C2C6973456D7074793A28293D3E6D6F64';
wwv_flow_imp.g_varchar2_table(111) := '656C2E656D7074792C0D0A2020202020202020736574466F637573546F3A28293D3E676C6F62616C2E617065782E6A51756572792868616E646C65735B305D292C0D0A20202020202020207365745374796C65546F3A28293D3E676C6F62616C2E617065';
wwv_flow_imp.g_varchar2_table(112) := '782E6A517565727928726F6F74292C0D0A202020202020202073686F773A28293D3E7B726F6F742E68696464656E3D66616C73653B7D2C686964653A28293D3E7B726F6F742E68696464656E3D747275653B7D2C0D0A202020202020202067657456616C';
wwv_flow_imp.g_varchar2_table(113) := '69646974793A28293D3E287B76616C69643A21636F6E6669672E7265717569726564207C7C20216D6F64656C2E656D7074792C76616C75654D697373696E673A2121636F6E6669672E7265717569726564202626206D6F64656C2E656D7074797D292C0D';
wwv_flow_imp.g_varchar2_table(114) := '0A202020202020202067657456616C69646174696F6E4D6573736167653A28293D3E636F6E6669672E7265717569726564202626206D6F64656C2E656D7074793F2743686F6F736520612076616C75652E273A27272C0D0A202020202020202064697370';
wwv_flow_imp.g_varchar2_table(115) := '6C617956616C7565466F723A76616C75653D3E537472696E672876616C7565292E73706C697428273A27292E6D617028783D3E666F726D6174287829292E6A6F696E282720E280942027290D0A2020202020207D293B0D0A202020207D0D0A2020202070';
wwv_flow_imp.g_varchar2_table(116) := '61696E7428293B72657475726E206170693B0D0A20207D0D0A2020636F6E7374206170693D7B4D6F64656C2C646F6D61696E2C6D6F756E742C76657273696F6E3A27302E312E30277D3B0D0A2020696628747970656F66206D6F64756C65213D3D27756E';
wwv_flow_imp.g_varchar2_table(117) := '646566696E656427202626206D6F64756C652E6578706F72747329206D6F64756C652E6578706F7274733D6170693B0D0A2020676C6F62616C2E4D61676E6574536C696465723D6170693B0D0A7D2928747970656F662077696E646F77213D3D27756E64';
wwv_flow_imp.g_varchar2_table(118) := '6566696E6564273F77696E646F773A676C6F62616C54686973293B0D0A';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(15855139513691203)
,p_plugin_id=>wwv_flow_imp.id(15844765216620605)
,p_file_name=>'apex-magnet-slider.js'
,p_mime_type=>'text/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2E6D732D736C696465727B626F726465723A31707820736F6C696420766172282D2D6D732D616363656E74293B626F726465722D7261646975733A313070783B2D2D6D732D616363656E743A233732353565373B2D2D6D732D747261636B3A2365366538';
wwv_flow_imp.g_varchar2_table(2) := '65663B2D2D6D732D746578743A233230323433623B2D2D6D732D6D757465643A233663373238343B626F782D73697A696E673A626F726465722D626F783B6D696E2D77696474683A303B77696474683A313030253B70616464696E673A38707820323470';
wwv_flow_imp.g_varchar2_table(3) := '7820313270783B636F6C6F723A766172282D2D6D732D74657874293B666F6E743A696E68657269747D2E6D732D736C69646572202A7B626F782D73697A696E673A626F726465722D626F787D2E6D732D736C69646572202E6D732D73756D6D6172797B64';
wwv_flow_imp.g_varchar2_table(4) := '6973706C61793A666C65783B616C69676E2D6974656D733A63656E7465723B6A7573746966792D636F6E74656E743A73706163652D6265747765656E3B6D696E2D6865696768743A343070783B6761703A313270783B6D617267696E2D626F74746F6D3A';
wwv_flow_imp.g_varchar2_table(5) := '313270787D2E6D732D736C69646572202E6D732D73656C656374696F6E7B636F6C6F723A766172282D2D6D732D616363656E74293B666F6E742D73697A653A323270783B666F6E742D7765696768743A3730303B666F6E742D76617269616E742D6E756D';
wwv_flow_imp.g_varchar2_table(6) := '657269633A746162756C61722D6E756D733B6F766572666C6F772D777261703A616E7977686572657D2E6D732D736C69646572202E6D732D636C6561727B626F726465723A303B6261636B67726F756E643A7472616E73706172656E743B666F6E743A69';
wwv_flow_imp.g_varchar2_table(7) := '6E68657269743B666F6E742D73697A653A313270783B636F6C6F723A766172282D2D6D732D6D75746564293B70616464696E673A3870783B637572736F723A706F696E7465723B626F726465722D7261646975733A3670787D2E6D732D736C6964657220';
wwv_flow_imp.g_varchar2_table(8) := '2E6D732D636C6561723A686F7665727B6261636B67726F756E643A766172282D2D6D732D747261636B297D2E6D732D736C69646572202E6D732D636C6561723A64697361626C65647B6F7061636974793A2E343B637572736F723A64656661756C747D2E';
wwv_flow_imp.g_varchar2_table(9) := '6D732D736C69646572202E6D732D7261696C7B706F736974696F6E3A72656C61746976653B6865696768743A373670783B746F7563682D616374696F6E3A6E6F6E653B637572736F723A706F696E7465723B757365722D73656C6563743A6E6F6E657D2E';
wwv_flow_imp.g_varchar2_table(10) := '6D732D736C69646572202E6D732D747261636B7B706F736974696F6E3A6162736F6C7574653B746F703A323470783B696E7365742D696E6C696E653A303B6865696768743A3870783B626F726465722D7261646975733A31303070783B6261636B67726F';
wwv_flow_imp.g_varchar2_table(11) := '756E643A766172282D2D6D732D747261636B293B6F766572666C6F773A68696464656E7D2E6D732D736C69646572202E6D732D66696C6C7B706F736974696F6E3A6162736F6C7574653B746F703A303B6865696768743A313030253B6261636B67726F75';
wwv_flow_imp.g_varchar2_table(12) := '6E643A766172282D2D6D732D616363656E74293B626F726465722D7261646975733A31303070783B7472616E736974696F6E3A7769647468202E35732063756269632D62657A696572282E33342C312E35362C2E36342C31292C696E7365742D696E6C69';
wwv_flow_imp.g_varchar2_table(13) := '6E652D7374617274202E35732063756269632D62657A696572282E33342C312E35362C2E36342C31297D2E6D732D736C69646572202E6D732D68616E646C657B706F736974696F6E3A6162736F6C7574653B746F703A3670783B77696474683A34347078';
wwv_flow_imp.g_varchar2_table(14) := '3B6865696768743A343470783B6D617267696E2D696E6C696E652D73746172743A2D323270783B70616464696E673A303B626F726465723A303B626F726465722D7261646975733A3530253B6261636B67726F756E643A7472616E73706172656E743B7A';
wwv_flow_imp.g_varchar2_table(15) := '2D696E6465783A323B637572736F723A677261623B746F7563682D616374696F6E3A6E6F6E653B646973706C61793A677269643B706C6163652D6974656D733A63656E7465723B7472616E736974696F6E3A696E7365742D696E6C696E652D7374617274';
wwv_flow_imp.g_varchar2_table(16) := '202E35732063756269632D62657A696572282E33342C312E35362C2E36342C31293B6F75746C696E652D6F66667365743A307D2E6D732D736C69646572202E6D732D68616E646C653A3A6265666F72657B636F6E74656E743A27273B706F736974696F6E';
wwv_flow_imp.g_varchar2_table(17) := '3A6162736F6C7574653B77696474683A323870783B6865696768743A323870783B626F726465723A33707820736F6C696420766172282D2D6D732D616363656E74293B6261636B67726F756E643A236666663B626F726465722D7261646975733A353025';
wwv_flow_imp.g_varchar2_table(18) := '3B626F782D736861646F773A302033707820397078202331623137333432393B7472616E736974696F6E3A626F782D736861646F77203132306D732C7472616E73666F726D202E3335732063756269632D62657A696572282E33342C312E35362C2E3634';
wwv_flow_imp.g_varchar2_table(19) := '2C31297D2E6D732D736C69646572202E6D732D677269707B706F736974696F6E3A72656C61746976653B77696474683A3670783B6865696768743A3670783B6261636B67726F756E643A766172282D2D6D732D616363656E74293B626F726465722D7261';
wwv_flow_imp.g_varchar2_table(20) := '646975733A3530257D2E6D732D736C696465722E6D732D6472616767696E67202E6D732D68616E646C653A3A6265666F72657B7472616E73666F726D3A7363616C6528312E3138297D2E6D732D736C69646572202E6D732D68616E646C653A686F766572';
wwv_flow_imp.g_varchar2_table(21) := '3A3A6265666F72652C2E6D732D736C69646572202E6D732D68616E646C653A666F6375732D76697369626C653A3A6265666F72657B626F782D736861646F773A30203020302036707820636F6C6F722D6D697828696E20737267622C766172282D2D6D73';
wwv_flow_imp.g_varchar2_table(22) := '2D616363656E7429203135252C7472616E73706172656E74292C302033707820397078202331623137333432393B7472616E73666F726D3A7363616C6528312E3036297D2E6D732D736C69646572202E6D732D68616E646C653A666F6375732D76697369';
wwv_flow_imp.g_varchar2_table(23) := '626C652C2E6D732D736C69646572202E6D732D636C6561723A666F6375732D76697369626C657B6F75746C696E653A32707820736F6C696420766172282D2D6D732D616363656E74297D2E6D732D736C69646572202E6D732D7469636B7B706F73697469';
wwv_flow_imp.g_varchar2_table(24) := '6F6E3A6162736F6C7574653B746F703A323570783B646973706C61793A666C65783B616C69676E2D6974656D733A63656E7465723B666C65782D646972656374696F6E3A636F6C756D6E3B77696474683A303B706F696E7465722D6576656E74733A6E6F';
wwv_flow_imp.g_varchar2_table(25) := '6E657D2E6D732D736C69646572202E6D732D646F747B646973706C61793A626C6F636B3B666C65782D736872696E6B3A303B77696474683A3670783B6865696768743A3670783B6261636B67726F756E643A236165623363343B626F726465722D726164';
wwv_flow_imp.g_varchar2_table(26) := '6975733A3530253B7A2D696E6465783A317D2E6D732D736C69646572202E6D732D696E2D72616E6765202E6D732D646F747B6261636B67726F756E643A636F6C6F722D6D697828696E20737267622C766172282D2D6D732D616363656E7429203435252C';
wwv_flow_imp.g_varchar2_table(27) := '7768697465297D2E6D732D736C69646572202E6D732D7469636B2D6C6162656C7B6D617267696E2D746F703A323470783B636F6C6F723A766172282D2D6D732D6D75746564293B666F6E742D73697A653A313270783B77686974652D73706163653A6E6F';
wwv_flow_imp.g_varchar2_table(28) := '777261703B666F6E742D76617269616E742D6E756D657269633A746162756C61722D6E756D737D2E6D732D736C696465722E6D732D656D707479202E6D732D66696C6C7B6F7061636974793A307D2E6D732D736C696465722E6D732D656D707479202E6D';
wwv_flow_imp.g_varchar2_table(29) := '732D73656C656374696F6E7B666F6E742D73697A653A313670783B636F6C6F723A766172282D2D6D732D6D75746564293B666F6E742D7765696768743A3430307D2E6D732D736C696465722E6D732D656D707479202E6D732D68616E646C653A3A626566';
wwv_flow_imp.g_varchar2_table(30) := '6F72657B626F726465722D7374796C653A6461736865647D2E6D732D736C696465722E6D732D64697361626C65647B6F7061636974793A2E357D2E6D732D736C696465722E6D732D64697361626C6564202E6D732D7261696C2C2E6D732D736C69646572';
wwv_flow_imp.g_varchar2_table(31) := '2E6D732D64697361626C6564202E6D732D68616E646C657B637572736F723A64656661756C747D2E6D732D736C696465722E6D732D6472616767696E67202E6D732D68616E646C657B637572736F723A6772616262696E677D2E6D732D736C696465722E';
wwv_flow_imp.g_varchar2_table(32) := '6D732D6472616767696E67202E6D732D66696C6C2C2E6D732D736C696465722E6D732D6472616767696E67202E6D732D68616E646C657B7472616E736974696F6E2D6475726174696F6E3A2E33737D406D65646961286D61782D77696474683A34383070';
wwv_flow_imp.g_varchar2_table(33) := '78297B2E6D732D736C696465727B70616464696E672D696E6C696E653A323070787D2E6D732D736C69646572202E6D732D7469636B2D6C6162656C7B666F6E742D73697A653A313070787D2E6D732D736C69646572202E6D732D73656C656374696F6E7B';
wwv_flow_imp.g_varchar2_table(34) := '666F6E742D73697A653A323070787D7D406D6564696128707265666572732D726564756365642D6D6F74696F6E3A726564756365297B2E6D732D736C69646572202A2C2E6D732D736C69646572202A3A3A6265666F72657B7472616E736974696F6E3A6E';
wwv_flow_imp.g_varchar2_table(35) := '6F6E6521696D706F7274616E747D7D406D6564696128666F726365642D636F6C6F72733A616374697665297B2E6D732D736C69646572202E6D732D747261636B7B626F726465723A31707820736F6C69642043616E766173546578747D2E6D732D736C69';
wwv_flow_imp.g_varchar2_table(36) := '646572202E6D732D66696C6C7B6261636B67726F756E643A486967686C696768747D2E6D732D736C69646572202E6D732D68616E646C653A3A6265666F72657B626F726465722D636F6C6F723A427574746F6E546578747D2E6D732D736C69646572202E';
wwv_flow_imp.g_varchar2_table(37) := '6D732D677269707B6261636B67726F756E643A427574746F6E546578747D7D2E6D732D736C69646572202E6D732D627562626C657B706F736974696F6E3A6162736F6C7574653B626F74746F6D3A343770783B6C6566743A3530253B7472616E73666F72';
wwv_flow_imp.g_varchar2_table(38) := '6D3A7472616E736C61746558282D35302529207472616E736C6174655928337078293B6261636B67726F756E643A766172282D2D6D732D616363656E74293B636F6C6F723A236666663B626F726465722D7261646975733A3770783B70616464696E673A';
wwv_flow_imp.g_varchar2_table(39) := '367078203970783B77686974652D73706163653A6E6F777261703B666F6E743A36303020313270782F312E322073797374656D2D75693B706F696E7465722D6576656E74733A6E6F6E653B6F7061636974793A303B7472616E736974696F6E3A6F706163';
wwv_flow_imp.g_varchar2_table(40) := '697479203130306D732C7472616E73666F726D203130306D737D2E6D732D736C69646572202E6D732D68616E646C653A686F766572202E6D732D627562626C652C2E6D732D736C69646572202E6D732D68616E646C653A666F6375732D76697369626C65';
wwv_flow_imp.g_varchar2_table(41) := '202E6D732D627562626C652C2E6D732D736C696465722E6D732D6472616767696E67202E6D732D68616E646C653A666F637573202E6D732D627562626C657B6F7061636974793A313B7472616E73666F726D3A7472616E736C61746558282D3530252920';
wwv_flow_imp.g_varchar2_table(42) := '7472616E736C617465592830297D2E6D732D736C696465722E6D732D61742D65646765202E6D732D68616E646C652C0D0A2E6D732D736C696465722E6D732D61742D65646765202E6D732D66696C6C7B7472616E736974696F6E2D74696D696E672D6675';
wwv_flow_imp.g_varchar2_table(43) := '6E6374696F6E3A63756269632D62657A696572282E32352C2E392C2E33352C31297D2E6D732D6C6162656C2D626F787B77696474683A313030253B746578742D616C69676E3A63656E7465727D2E6D732D6C6162656C2D626F78202E742D466F726D2D6C';
wwv_flow_imp.g_varchar2_table(44) := '6162656C7B646973706C61793A626C6F636B3B666F6E742D7765696768743A3730303B746578742D616C69676E3A63656E7465727D';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(15853805239684114)
,p_plugin_id=>wwv_flow_imp.id(15844765216620605)
,p_file_name=>'apex-magnet-slider.min.css'
,p_mime_type=>'text/css'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2166756E6374696F6E2865297B2275736520737472696374223B636F6E737420743D3165362C6E3D2F5E2D3F283F3A307C5B312D395D5C642A29283F3A5C2E5C647B312C367D293F242F3B66756E6374696F6E20732865297B636F6E737420733D537472';
wwv_flow_imp.g_varchar2_table(2) := '696E672865292E7472696D28293B696628216E2E74657374287329297468726F77206E6577204572726F72282255736520706C61696E206E756D62657273207769746820757020746F203620646563696D616C20706C616365732E22293B636F6E737420';
wwv_flow_imp.g_varchar2_table(3) := '693D4E756D6265722873293B696628214E756D6265722E697346696E6974652869297C7C4D6174682E6162732869293E316539297468726F77206E6577204572726F7228224E756D62657273206D757374206265206265747765656E202D312062696C6C';
wwv_flow_imp.g_varchar2_table(4) := '696F6E20616E6420312062696C6C696F6E2E22293B72657475726E204D6174682E726F756E6428692A74297D66756E6374696F6E20692865297B6C6574206E3B6966286E756C6C213D652E76616C75657326262222213D3D652E76616C756573297B636F';
wwv_flow_imp.g_varchar2_table(5) := '6E737420743D41727261792E6973417272617928652E76616C756573293F652E76616C7565733A537472696E6728652E76616C756573292E73706C697428222C22293B6E3D742E6D61702873297D656C73657B636F6E737420743D7328652E6D696E3F3F';
wwv_flow_imp.g_varchar2_table(6) := '30292C693D7328652E6D61783F3F313030292C613D7328652E737465703F3F3130293B696628613C3D307C7C693C3D747C7C28692D74292561213D3D30297468726F77206E6577204572726F7228224D6178206D75737420657863656564206D696E2061';
wwv_flow_imp.g_varchar2_table(7) := '6E6420286D617820E28892206D696E29206D757374206469766964652065786163746C7920627920737465702E22293B636F6E737420723D28692D74292F612B313B696628723E31303031297468726F77206E6577204572726F72282255736520617420';
wwv_flow_imp.g_varchar2_table(8) := '6D6F737420312C3030312073746F70732E22293B6E3D41727261792E66726F6D287B6C656E6774683A727D2C28652C6E293D3E742B6E2A61297D6966286E2E6C656E6774683C327C7C6E2E6C656E6774683E313030317C7C6E2E736F6D652828652C7429';
wwv_flow_imp.g_varchar2_table(9) := '3D3E742626653C3D6E5B742D315D29297468726F77206E6577204572726F722822537570706C792032E28093312C30303120756E69717565206E756D6265727320696E20696E6372656173696E67206F726465722E22293B72657475726E206E2E6D6170';
wwv_flow_imp.g_varchar2_table(10) := '28653D3E652F74297D636C61737320617B636F6E7374727563746F7228653D7B7D297B696628746869732E76616C7565733D692865292C746869732E72616E67653D2272616E6765223D3D3D652E6D6F64652C652E6D6F64652626215B2273696E676C65';
wwv_flow_imp.g_varchar2_table(11) := '222C2272616E6765225D2E696E636C7564657328652E6D6F646529297468726F77206E6577204572726F7228224D6F6465206D7573742062652073696E676C65206F722072616E67652E22293B746869732E696E64696365733D746869732E72616E6765';
wwv_flow_imp.g_varchar2_table(12) := '3F5B302C746869732E76616C7565732E6C656E6774682D315D3A5B305D2C746869732E656D7074793D21303B7472797B746869732E73657428652E76616C75653F3F2222297D63617463682865297B746869732E736574282222297D7D7365742865297B';
wwv_flow_imp.g_varchar2_table(13) := '69662822223D3D3D657C7C6E756C6C3D3D652972657475726E20746869732E656D7074793D21302C766F696428746869732E696E64696365733D746869732E72616E67653F5B302C746869732E76616C7565732E6C656E6774682D315D3A5B305D293B63';
wwv_flow_imp.g_varchar2_table(14) := '6F6E7374206E3D537472696E672865292E73706C697428223A22293B6966286E2E6C656E677468213D3D28746869732E72616E67653F323A3129297468726F77206E6577204572726F7228746869732E72616E67653F22557365206C6F7765723A757070';
wwv_flow_imp.g_varchar2_table(15) := '65722E223A22557365206F6E65206E756D6265722E22293B636F6E737420693D6E2E6D617028653D3E746869732E76616C7565732E696E6465784F6628732865292F7429293B696628692E736F6D6528653D3E653C30297C7C746869732E72616E676526';
wwv_flow_imp.g_varchar2_table(16) := '26695B305D3E695B315D297468726F77206E6577204572726F72282243686F6F736520616C6C6F776564206E756D6265727320696E20617363656E64696E67206F726465722E22293B746869732E696E64696365733D692C746869732E656D7074793D21';
wwv_flow_imp.g_varchar2_table(17) := '317D6D6F766528652C74297B636F6E7374206E3D746869732E72616E67652626313D3D3D653F746869732E696E64696365735B305D3A302C733D746869732E72616E67652626303D3D3D653F746869732E696E64696365735B315D3A746869732E76616C';
wwv_flow_imp.g_varchar2_table(18) := '7565732E6C656E6774682D313B746869732E696E64696365735B655D3D4D6174682E6D6178286E2C4D6174682E6D696E28732C4D6174682E726F756E6428742929292C746869732E656D7074793D21317D67657428297B72657475726E20746869732E65';
wwv_flow_imp.g_varchar2_table(19) := '6D7074793F22223A746869732E696E64696365732E6D617028653D3E746869732E76616C7565735B655D292E6A6F696E28223A22297D7D636F6E737420723D7B4D6F64656C3A612C646F6D61696E3A692C6D6F756E743A66756E6374696F6E28742C6E3D';
wwv_flow_imp.g_varchar2_table(20) := '7B7D297B636F6E737420733D22737472696E67223D3D747970656F6620743F646F63756D656E742E676574456C656D656E74427949642874293A743B6966282173297468726F77206E6577204572726F7228224D61676E657420536C6964657220696E70';
wwv_flow_imp.g_varchar2_table(21) := '7574206E6F7420666F756E642E22293B732E6D61676E6574536C696465722626732E6D61676E6574536C696465722E64657374726F7928293B636F6E737420693D6E65772061287B2E2E2E6E2C76616C75653A732E76616C75657D292C723D692E676574';
wwv_flow_imp.g_varchar2_table(22) := '28292C6C3D732E747970653B732E747970653D2268696464656E223B6C6574206F3D21216E2E64697361626C65642C643D6E756C6C2C753D22222C633D303B636F6E7374206D3D5B5D3B66756E6374696F6E207028652C742C6E297B652E616464457665';
wwv_flow_imp.g_varchar2_table(23) := '6E744C697374656E657228742C6E292C6D2E707573682828293D3E652E72656D6F76654576656E744C697374656E657228742C6E29297D66756E6374696F6E206828652C742C6E297B636F6E737420733D646F63756D656E742E637265617465456C656D';
wwv_flow_imp.g_varchar2_table(24) := '656E742865293B72657475726E20732E636C6173734E616D653D742C6E756C6C213D6E262628732E74657874436F6E74656E743D6E292C737D636F6E737420673D682822646976222C226D732D736C6964657222293B6E2E616363656E7426262F5E235B';
wwv_flow_imp.g_varchar2_table(25) := '302D39612D665D7B367D242F692E74657374286E2E616363656E74292626672E7374796C652E73657450726F706572747928222D2D6D732D616363656E74222C6E2E616363656E74293B636F6E737420623D682822646976222C226D732D73756D6D6172';
wwv_flow_imp.g_varchar2_table(26) := '7922292C763D6828227370616E222C226D732D73656C656374696F6E22292C663D682822627574746F6E222C226D732D636C656172222C6E2E636C6561724C6162656C7C7C22436C65617222293B662E747970653D22627574746F6E222C662E73657441';
wwv_flow_imp.g_varchar2_table(27) := '74747269627574652822617269612D6C6162656C222C286E2E636C6561724C6162656C7C7C22436C65617222292B2220222B286E2E6C6162656C7C7C732E696429292C622E617070656E642876292C2131213D3D6E2E616C6C6F77436C6561722626622E';
wwv_flow_imp.g_varchar2_table(28) := '617070656E642866293B636F6E737420793D682822646976222C226D732D7261696C22292C773D682822646976222C226D732D747261636B22292C783D682822646976222C226D732D66696C6C22292C453D682822646976222C226D732D7469636B7322';
wwv_flow_imp.g_varchar2_table(29) := '293B772E617070656E642878292C792E617070656E6428772C45293B636F6E737420413D653D3E286E2E7072656669787C7C2222292B537472696E672865292B286E2E7375666669787C7C2222292C4D3D692E696E64696365732E6D61702828652C7429';
wwv_flow_imp.g_varchar2_table(30) := '3D3E7B636F6E737420613D682822627574746F6E222C226D732D68616E646C6522293B612E747970653D22627574746F6E222C612E69643D732E69642B225F48414E444C455F222B742C612E7365744174747269627574652822726F6C65222C22736C69';
wwv_flow_imp.g_varchar2_table(31) := '64657222292C612E7365744174747269627574652822617269612D6F7269656E746174696F6E222C22686F72697A6F6E74616C22292C612E7365744174747269627574652822617269612D6C6162656C222C286E2E6C6162656C7C7C732E6964292B2869';
wwv_flow_imp.g_varchar2_table(32) := '2E72616E67653F743F2220E280942075707065722076616C7565223A2220E28094206C6F7765722076616C7565223A222229293B636F6E737420723D732E6765744174747269627574652822617269612D646573637269626564627922293B7265747572';
wwv_flow_imp.g_varchar2_table(33) := '6E20722626612E7365744174747269627574652822617269612D6465736372696265646279222C72292C6E2E72657175697265642626612E7365744174747269627574652822617269612D7265717569726564222C227472756522292C612E617070656E';
wwv_flow_imp.g_varchar2_table(34) := '64286828227370616E222C226D732D6772697022292C6828227370616E222C226D732D627562626C652229292C612E6C6173744368696C642E7365744174747269627574652822617269612D68696464656E222C227472756522292C792E617070656E64';
wwv_flow_imp.g_varchar2_table(35) := '2861292C617D292C533D5B5D2C6B3D4D6174682E6D696E28692E76616C7565732E6C656E6774682C4D6174682E6D617828322C4D6174682E6D696E2832312C4E756D626572286E2E6D61785469636B73297C7C31312929293B5B2E2E2E6E657720536574';
wwv_flow_imp.g_varchar2_table(36) := '2841727261792E66726F6D287B6C656E6774683A6B7D2C28652C74293D3E4D6174682E726F756E6428742A28692E76616C7565732E6C656E6774682D31292F286B2D31292929295D2E666F724561636828653D3E7B636F6E737420743D6828227370616E';
wwv_flow_imp.g_varchar2_table(37) := '222C226D732D7469636B22293B742E7374796C652E696E736574496E6C696E6553746172743D652F28692E76616C7565732E6C656E6774682D31292A3130302B2225222C742E617070656E64286828227370616E222C226D732D646F7422292C68282273';
wwv_flow_imp.g_varchar2_table(38) := '70616E222C226D732D7469636B2D6C6162656C222C537472696E6728692E76616C7565735B655D2929292C452E617070656E642874292C532E70757368285B652C745D297D292C672E617070656E6428622C79292C732E61667465722867293B636F6E73';
wwv_flow_imp.g_varchar2_table(39) := '74204C3D732E636C6F7365737428222E742D466F726D2D6669656C64436F6E7461696E657222293F2E717565727953656C6563746F7228222E742D466F726D2D6C6162656C436F6E7461696E657222293B4C26264C2E636C6173734C6973742E61646428';
wwv_flow_imp.g_varchar2_table(40) := '226D732D6C6162656C2D626F7822293B636F6E737420433D28293D3E2272746C223D3D3D676574436F6D70757465645374796C652867292E646972656374696F6E3B66756E6374696F6E204928297B732E76616C75653D692E67657428292C672E636C61';
wwv_flow_imp.g_varchar2_table(41) := '73734C6973742E746F67676C6528226D732D656D707479222C692E656D707479292C672E636C6173734C6973742E746F67676C6528226D732D64697361626C6564222C6F292C762E74657874436F6E74656E743D692E656D7074793F6E2E656D7074794C';
wwv_flow_imp.g_varchar2_table(42) := '6162656C7C7C2243686F6F736520612076616C7565223A692E696E64696365732E6D617028653D3E4128692E76616C7565735B655D29292E6A6F696E282220E280942022292C662E64697361626C65643D6F7C7C692E656D7074792C672E636C6173734C';
wwv_flow_imp.g_varchar2_table(43) := '6973742E746F67676C6528226D732D61742D65646765222C692E696E64696365732E736F6D6528653D3E303D3D3D657C7C653D3D3D692E76616C7565732E6C656E6774682D3129293B636F6E737420653D692E72616E67653F692E696E64696365735B30';
wwv_flow_imp.g_varchar2_table(44) := '5D3A302C743D692E696E64696365735B692E696E64696365732E6C656E6774682D315D3B782E7374796C652E696E736574496E6C696E6553746172743D652F28692E76616C7565732E6C656E6774682D31292A3130302B2225222C782E7374796C652E77';
wwv_flow_imp.g_varchar2_table(45) := '696474683D28742D65292F28692E76616C7565732E6C656E6774682D31292A3130302B2225222C4D2E666F72456163682828652C74293D3E7B652E7374796C652E696E736574496E6C696E6553746172743D692E696E64696365735B745D2F28692E7661';
wwv_flow_imp.g_varchar2_table(46) := '6C7565732E6C656E6774682D31292A3130302B2225222C652E64697361626C65643D6F2C652E7365744174747269627574652822617269612D76616C75656D696E222C692E76616C7565735B692E72616E67652626313D3D3D743F692E696E6469636573';
wwv_flow_imp.g_varchar2_table(47) := '5B305D3A305D292C652E7365744174747269627574652822617269612D76616C75656D6178222C692E76616C7565735B692E72616E67652626303D3D3D743F692E696E64696365735B315D3A692E76616C7565732E6C656E6774682D315D292C652E7365';
wwv_flow_imp.g_varchar2_table(48) := '744174747269627574652822617269612D76616C75656E6F77222C692E76616C7565735B692E696E64696365735B745D5D292C652E7365744174747269627574652822617269612D76616C756574657874222C692E656D7074793F6E2E656D7074794C61';
wwv_flow_imp.g_varchar2_table(49) := '62656C7C7C224E6F2076616C75652073656C6563746564223A4128692E76616C7565735B692E696E64696365735B745D5D29292C652E7469746C653D4128692E76616C7565735B692E696E64696365735B745D5D292C652E717565727953656C6563746F';
wwv_flow_imp.g_varchar2_table(50) := '7228222E6D732D627562626C6522292E74657874436F6E74656E743D652E7469746C657D292C532E666F724561636828285B6E2C735D293D3E732E636C6173734C6973742E746F67676C6528226D732D696E2D72616E6765222C21692E656D7074792626';
wwv_flow_imp.g_varchar2_table(51) := '6E3E3D6526266E3C3D7429297D66756E6374696F6E20712865297B732E64697370617463684576656E74286E6577204576656E7428652C7B627562626C65733A21307D29297D66756E6374696F6E20442865297B692E6765742829213D3D652626712822';
wwv_flow_imp.g_varchar2_table(52) := '6368616E676522297D66756E6374696F6E205628652C74297B636F6E7374206E3D692E67657428293B692E6D6F766528652C74292C4928292C6E213D3D692E67657428292626712822696E70757422297D66756E6374696F6E204E2865297B636F6E7374';
wwv_flow_imp.g_varchar2_table(53) := '20743D792E676574426F756E64696E67436C69656E745265637428293B6C6574206E3D4D6174682E6D617828302C4D6174682E6D696E28312C28652E636C69656E74582D742E6C656674292F742E776964746829293B72657475726E284328293F312D6E';
wwv_flow_imp.g_varchar2_table(54) := '3A6E292A28692E76616C7565732E6C656E6774682D31297D66756E6374696F6E20552865297B642626642E69643D3D3D652E706F696E7465724964262628643D6E756C6C2C672E636C6173734C6973742E72656D6F766528226D732D6472616767696E67';
wwv_flow_imp.g_varchar2_table(55) := '22292C44287529297D7028792C22706F696E746572646F776E222C653D3E7B6966286F7C7C21652E69735072696D6172797C7C30213D3D652E627574746F6E2972657475726E3B636F6E737420743D4D2E66696E64496E64657828743D3E743D3D3D652E';
wwv_flow_imp.g_varchar2_table(56) := '7461726765747C7C742E636F6E7461696E7328652E74617267657429292C6E3D4E2865293B6C657420733D743B696628733C3029696628692E72616E6765297B636F6E737420653D4D6174682E616273286E2D692E696E64696365735B305D292C743D4D';
wwv_flow_imp.g_varchar2_table(57) := '6174682E616273286E2D692E696E64696365735B315D293B733D653D3D3D743F6E3C692E696E64696365735B305D3F303A6E3E692E696E64696365735B315D3F313A633A653C743F303A317D656C736520733D303B643D7B68616E646C653A732C69643A';
wwv_flow_imp.g_varchar2_table(58) := '652E706F696E74657249647D2C633D732C753D692E67657428292C672E636C6173734C6973742E61646428226D732D6472616767696E6722292C4D5B735D2E666F63757328292C792E736574506F696E7465724361707475726528652E706F696E746572';
wwv_flow_imp.g_varchar2_table(59) := '4964292C5628732C6E292C652E70726576656E7444656661756C7428297D292C7028792C22706F696E7465726D6F7665222C653D3E7B642626642E69643D3D3D652E706F696E746572496426265628642E68616E646C652C4E286529297D292C7028792C';
wwv_flow_imp.g_varchar2_table(60) := '22706F696E7465727570222C55292C7028792C22706F696E74657263616E63656C222C55292C7028792C226C6F7374706F696E74657263617074757265222C55292C4D2E666F72456163682828652C74293D3E7B7028652C22666F637573222C28293D3E';
wwv_flow_imp.g_varchar2_table(61) := '7B633D742C4D2E666F724561636828653D3E652E7374796C652E7A496E6465783D223222292C652E7374796C652E7A496E6465783D2233227D292C7028652C226B6579646F776E222C653D3E7B6966286F2972657475726E3B6C6574206E3D692E696E64';
wwv_flow_imp.g_varchar2_table(62) := '696365735B745D3B73776974636828652E6B6579297B63617365224172726F775269676874223A6E2B3D4328293F2D313A313B627265616B3B63617365224172726F774C656674223A6E2B3D4328293F313A2D313B627265616B3B63617365224172726F';
wwv_flow_imp.g_varchar2_table(63) := '775570223A6E2B2B3B627265616B3B63617365224172726F77446F776E223A6E2D2D3B627265616B3B6361736522506167655570223A6E2B3D31303B627265616B3B636173652250616765446F776E223A6E2D3D31303B627265616B3B6361736522486F';
wwv_flow_imp.g_varchar2_table(64) := '6D65223A6E3D303B627265616B3B6361736522456E64223A6E3D692E76616C7565732E6C656E6774682D313B627265616B3B64656661756C743A72657475726E7D652E70726576656E7444656661756C7428293B636F6E737420733D692E67657428293B';
wwv_flow_imp.g_varchar2_table(65) := '5628742C6E292C442873297D297D292C7028662C22636C69636B222C28293D3E7B636F6E737420653D692E67657428293B646F63756D656E742E616374697665456C656D656E742626646F63756D656E742E616374697665456C656D656E742E626C7572';
wwv_flow_imp.g_varchar2_table(66) := '28292C692E736574282222292C4928292C712822696E70757422292C442865297D292C732E666F726D26267028732E666F726D2C227265736574222C28293D3E71756575654D6963726F7461736B2828293D3E7B692E7365742872292C4928297D29293B';
wwv_flow_imp.g_varchar2_table(67) := '636F6E7374206A3D7B67657456616C75653A28293D3E692E67657428292C73657456616C75652865297B692E7365742865292C4928297D2C64697361626C6528297B6F3D21302C4928297D2C656E61626C6528297B6F3D21312C4928297D2C6973446973';
wwv_flow_imp.g_varchar2_table(68) := '61626C65643A28293D3E6F2C666F63757328297B4D5B305D2E666F63757328297D2C64657374726F7928297B6D2E666F724561636828653D3E652829292C4C26264C2E636C6173734C6973742E72656D6F766528226D732D6C6162656C2D626F7822292C';
wwv_flow_imp.g_varchar2_table(69) := '672E72656D6F766528292C732E747970653D6C2C64656C65746520732E6D61676E6574536C696465727D2C6D6F64656C3A692C726F6F743A677D3B72657475726E20732E6D61676E6574536C696465723D6A2C652E617065782626652E617065782E6974';
wwv_flow_imp.g_varchar2_table(70) := '656D26262266756E6374696F6E223D3D747970656F6620652E617065782E6974656D2E6372656174652626652E617065782E6974656D2E63726561746528732E69642C7B6974656D5F747970653A224D41474E45545F534C49444552222C67657456616C';
wwv_flow_imp.g_varchar2_table(71) := '75653A6A2E67657456616C75652C73657456616C75653A6A2E73657456616C75652C64697361626C653A6A2E64697361626C652C656E61626C653A6A2E656E61626C652C697344697361626C65643A6A2E697344697361626C65642C69734368616E6765';
wwv_flow_imp.g_varchar2_table(72) := '643A28293D3E692E6765742829213D3D722C6973456D7074793A28293D3E692E656D7074792C736574466F637573546F3A28293D3E652E617065782E6A5175657279284D5B305D292C7365745374796C65546F3A28293D3E652E617065782E6A51756572';
wwv_flow_imp.g_varchar2_table(73) := '792867292C73686F773A28293D3E7B672E68696464656E3D21317D2C686964653A28293D3E7B672E68696464656E3D21307D2C67657456616C69646974793A28293D3E287B76616C69643A216E2E72657175697265647C7C21692E656D7074792C76616C';
wwv_flow_imp.g_varchar2_table(74) := '75654D697373696E673A21216E2E72657175697265642626692E656D7074797D292C67657456616C69646174696F6E4D6573736167653A28293D3E6E2E72657175697265642626692E656D7074793F2243686F6F736520612076616C75652E223A22222C';
wwv_flow_imp.g_varchar2_table(75) := '646973706C617956616C7565466F723A653D3E537472696E672865292E73706C697428223A22292E6D617028653D3E41286529292E6A6F696E282220E280942022297D292C4928292C6A7D2C76657273696F6E3A22302E312E30227D3B22756E64656669';
wwv_flow_imp.g_varchar2_table(76) := '6E656422213D747970656F66206D6F64756C6526266D6F64756C652E6578706F7274732626286D6F64756C652E6578706F7274733D72292C652E4D61676E6574536C696465723D727D2822756E646566696E656422213D747970656F662077696E646F77';
wwv_flow_imp.g_varchar2_table(77) := '3F77696E646F773A676C6F62616C54686973293B';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(15855485066691204)
,p_plugin_id=>wwv_flow_imp.id(15844765216620605)
,p_file_name=>'apex-magnet-slider.min.js'
,p_mime_type=>'text/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
prompt --application/end_environment
begin
wwv_flow_imp.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false)
);
commit;
end;
/
set verify on feedback on define on
prompt  ...done
