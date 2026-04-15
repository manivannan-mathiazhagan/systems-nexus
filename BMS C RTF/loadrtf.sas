/***************************************************************************************
**     Program Name:        loadrtf.sas
**     Programmer:          Bryan Lange (langeb2)
**     Date:                31MAR2023
**     Project:             Global
**     Purpose:             Creates tagset.bmsrtf and style=prisrtf for ODS output
**	   Parameters:   Required: &protocol: set to your protocol number for the output you are generating
**					 				 Optional: &display: set to (if anything) what you want centered in the header example display=DRAFT
**									 Optional: &escchar: Default is ^ can set to something else if need to display ^ in output or user desires alternate
**                             ODS escape character. NOTE: This does not SET the ODS escape character, just tells the macro
**                             what character to use. i.e. if set to ~ because user wants to use ~ still need to have ods escapchar=~; statement
**                             in the program. 
**									 Optional: &orientation: Default is LANDSCAPE, can set to PORTRAIT. NOTE: Only moves the protocol and page number to 
**                             align with orientation, output orentation still defined by options statement in program , i.e.
**                             options orientation=landscape; or options orientation=portrait; 
**									 Optional: &lrmargin: Default is 1.0 can set to any positive value (note doesn't line up if going less then 0.25 as 
**                             SAS ODS RTF requires 0.25in margin on left and right for ODS output thru SAS to RTF
**									 Optional: &fsize: Default is 8. Should not be smaller than 8. Can increase, but BMS standard is 8pt font. 
**	   Sameple Call: %loadrtf(protocol=IM042-P02, display=DRAFT); 
**                          
**
**     Modification History:
**     Date          Version   Programmer                  Description
**     ------------ -------   -----------------------      --------------------------------
****************************************************************************************
**                     Copyright: Bristol-Myers Squibb Company
****************************************************************************************/



%macro loadrtf(protocol=, display=, escchar=^, orientation=LANDSCAPE, lrmargin=1.0, fsize=8); 

%if %length(&protocol)=0  %then %do;
	%put ERROR: the macro parameter protocol is null, please input a protocol;
%end;

/*create the bmsrtf tagset*/
proc template; 

	measured; 
	define tagset tagsets.bmsrtf; 
	parent=tagsets.rtf; *parent is the SAS generated tagsets.rtf; 
	default_style="styles.rtf" ;


   
/*only keep definitions where changes from parent are made search for "added by BL" for changes*/
   define event doc_start;
      start:

         open body_tbl;
      put "{\stylesheet{\widctlpar\adjustright\fs16\cgrid\snext0 Normal;}" NL;
      put "{\*\cs10\additive Default Paragraph Font;}}" NL;
      set $generic getoption("generic");

      do /if cmp( $generic, "NOGENERIC");
         put "{\info";

         do /if TITLE;
            put "{\title " RTFENCODE(TITLE) "}";

         else;
            put "{\title 9.4 SAS System Output}";
         done;


         do /if AUTHOR;
            put "{\author " RTFENCODE(AUTHOR) "}";

         else;
            put "{\author SAS Version 9.4}";
         done;


         do /if OPERATOR;
            put "{\operator " RTFENCODE(OPERATOR) "}";

         else;
            put "{\operator SAS Version 9.4}";
         done;

         put "{\version1}}" NL;
      done;

      put "\widowctrl\ftnbj\aenddoc\formshade\viewkind1\viewscale100\pgbrdrhead\pgbrdrfoot\fet0" NL;
      put "\paperw" OUTPUTWIDTH "\paperh" OUTPUTHEIGHT;
      put "\margl" LEFTMARGIN "\margr" RIGHTMARGIN;
      put "\margt" TOPMARGIN "\margb" BOTTOMMARGIN;
      put "\pgnstart" VALUE;
	    **put "\pard\fs16\f1\par" NL ; *added by BL in order to put a blank before title1 on first page; 
      put NL;
      close;
   end;

   define event pagebreak;
      start:

         open body_tbl;

         do /if $contents_page and $first_page;
            put "\sectd\linex0\endnhere" NL;
            put $$contents_title_tbl;
            put "\pard\par\par\plain{\field\fldedit{\*\fldinst { TOC \tcf67 \\h }}}" NL;
            unset $$contents_title_tbl;
            put "\sect";
            set $sbreak "ON";
         done;

         do /if cmp( "OFF", $startpage) and  ^ $first_page;
            unset $first_page;
            break /if ^$first_page;
         done;


         do /if ^$no_section_data;

            do /if value or exists( $watertext);
               put "{\pard\par}" NL /if ^$first_page and  ^ exists( $watertext);
               put "\sectd\linex0\endnhere" /if $first_page;
               put "\pard\sect\sectd\linex0\endnhere" /if ^$first_page;

               do /if contains( VALUE, "LANDSCAPE");
                  put "\pgwsxn" WIDTH "\pghsxn" HEIGHT "\lndscpsxn";
                  set $orientation "LANDSCAPE" /if $first_page;

               else /if contains( VALUE, "PORTRAIT");
                  put "\pgwsxn" WIDTH "\pghsxn" HEIGHT;
               done;

               put "\pgnrestart\pgnstarts" LIST_INDEX /if contains( VALUE, "PAGENO");
               put "\sbkcol\cols" PAGE_COLUMNS /if exists( PAGE_COLUMNS);

            else;

               do /if ^$first_page;

                  do /if ^exists( $watertext);
                     put "{\pard\page\par}" NL; 
                  done;

               done;

               put "\pard\sect" /if ^$first_page;

               do /if $sbreak;
                  put "\sectd\linex0\endnhere";
                  unset $sbreak;

               else;

                  do /if ^exists( $watertext);
                     put "\sectd\linex0\endnhere\sbknone";

                  else;
                     put "\sectd\linex0\endnhere";
                  done;

               done;

               put "\pgwsxn" WIDTH "\pghsxn" HEIGHT /if contains( $orientation, "LANDSCAPE");
            done;


            do /if $contents_page;
               unset $contents_page;
               put "\pgnrestart\pgnstarts1";
            done;

            put $sect_data;
            put NL;
            put "\headery" TOPMARGIN "\footery" BOTTOMMARGIN;
            put "\marglsxn" LEFTMARGIN "\margrsxn" RIGHTMARGIN;
            put "\margtsxn" TOPMARGIN "\margbsxn" BOTTOMMARGIN;
            set $pagecols PAGE_COLUMNS /if exists( PAGE_COLUMNS);
            put NL;

         else;

            do /if ^$first_page;

               do /if exists( PAGE_COLUMNS);
                  put "{\pard\column\par}" NL; 

               else;
                  put "{\pard\page\par}" NL /if ^$first_page; 
               done;

            done;

         done;


         do /if ^$date_location or  ^ $pageno_location;
            put "{\header\pard\plain\qr\pvmrg\phmrg\posxr\posy0{" NL; 	 *added by BL uncomment this line to return to normal; 

            put " " /if exists( PAGE_COLUMNS);
            put $$bodydate_tbl /if ^$date_location;
            put $$pageno_tbl /if ^$pageno_location;

            do /if $watertext;
               put $$watertext_tbl;

            else;
               put $$watermark_tbl;
            done;

            *do /if ^$$pageno_tbl; 
				put "}}" NL; *maybe here; 
			*done;
         done;


         do /if $date_location or $pageno_location;
            put "{\footer\pard\plain\qr\pvmrg\phmrg\posxr\posy0{" NL;
            put $$bodydate_tbl /if $date_location;
            put $$pageno_tbl /if $pageno_location;
            put "}}" NL;
         done;

         close;

      finish:

         do /if ^$pagecols;

            open body_tbl;
            	**put "{\pard\par}" NL /if $first_page; *removed added by BL to rid paragraph mark put on page1 out of control;

            do /if ^$first_page;
               **put "{\pard\par}" NL /if $watertext or contains( $orientation, "LANDSCAPE"); *left in so when page breaks are not implicit can still have title1 show up on line2 past first page;
            done;

            close;
         done;

         unset $first_page;
         set $startpage $previous_startpage /if cmp( "NOW", $startpage);
   end;

   define event implicit_pagebreak;
      start:

	  
         do /if cmp( "table_body", $section_tbl) and  ^ VALUE;

         trigger publish start;
		  

      else /if cmp( "table_head", $section_tbl) and cmp ( "PARTIAL", VALUE);

         trigger publish start;
		
      else;
         unset $$table_head;
         unset $$table_body;
         unset $$table_foot;
      done;

      open body_tbl;
      put "{\pard\par}" NL;  ** this puts a blank row before footers start;

      do /if $table_rows;

         do /if $last_row_border_tr;
            put $last_row_border_tr NL;
            unset $last_row_border_tr;
         done;


      else;

         do /if $last_row_border;
            put $last_row_border NL;
            unset $last_row_border;
         done;

      done;

      put $$continue_tbl /if ^cmp( "FLUSH", VALUE) and $continue_tag;
      put $$footnotes_tbl;


      do /if $pagecols;
         put "\pard\sect\sbkcol\cols" $pagecols;
         put $sect_data;
         put  NL;
		
      else;

        do /if ^PAGE_COLUMNS;
		   
           put "{\pard\page\par}" NL /if ^cmp( "USERTEXT", $no_tables);
		    
         done;

      done;

	  put $$titles_tbl NL;
	  	   put "\pard\fs16\f1\par" NL ; *added by BL to make sure paragraph mark between last title and body of table; 
      close;
   	  set $just_broke_page "on" /if $order_repeat;    
   end;

   

  

   define event titles;
      start:

         open body_tbl;
      put $$titles_tbl;
	  put "\pard\fs16\f1\par" NL ; *added by BL in order to put a blank after last title; 
      close;
   end;

 

   define event data;
      start:

         trigger redirect;

      do /if $tables_off;
         put "\pard\plain";

      else;
         put "\pard\plain\intbl";
         put "\keepn" /if KEEPN;
         put "\sb" TOPMARGIN;
         put "\sa" BOTTOMMARGIN;

         do /if $constrain_height and  ^ GRSEG;

            do /if ^$inline_fontsize;

               do /if OUTPUTHEIGHT GT 0;
                  put "\sl-" OUTPUTHEIGHT;

               else;
                  eval $thissize OUTPUTHEIGHT * -1;
                  put "\sl" $thissize;
               done;

            done;

         done;

      done;

      unset $inline_fontsize /if $inline_fontsize;
      put "\fs" FONT_SIZE;
      put "\cf" FOREGROUND;

      do /if cmp( JUST, "j");

         do /if cmp( TEXTJUSTIFY, "inter_character");
            put "\qd";

         else;
            put "\qj";
         done;


      else;
         put "\q" JUST;
      done;


      do /if $just_broke_page;

         do /if ^VALUE and $first_row_after_break and cmp( $section_tbl, "table_body");
            put "\q" $column_just[colstart ] /if $column_just[colstart];
         done;

      done;

      put "\fi" INDENT /if INDENT;
      put $fontstyle[FONT_STYLE ] /if FONT_STYLE;
      put "\f" LIST_INDEX;
      put $fontweight[FONT_WEIGHT ] /if FONT_WEIGHT;
/**      put "\tqdec\tx400" /if COLWIDTH;**/
      put $spec[text_decoration ] / exists( text_decoration);
      put "{";

      do /if PREIMAGE;
         set $stream_name PREIMAGE;
         putstream $stream_name;
      done;


      do /if $preimage_name;
         set $stream_name $preimage_name;
         putstream $stream_name;
         unset $preimage_name;
      done;


      do /if URL;
         set $url_flag "1";
         put "{\field{\*\fldinst { HYPERLINK """;
         put RTFENCODE(URL);
         put """}}{\fldrslt {";
         put "\cf" LINKCOLOR " " /if LINKCOLOR;
      done;


      do /if GRSEG;
         set $stream_name GRSEG;
         putstream $stream_name;
      done;

      put RTFENCODE(VALUE);

      do /if $order_repeat and $proc_name;

         do /if VALUE and cmp( $section_tbl, "table_body");

            do /if ^cmp( ROWSPAN, "1");
               unset $column_text /if cmp( colstart, "1");
               unset $column_just /if cmp( colstart, "1");
               set $column_text[colstart ] VALUE;
               set $column_just[colstart ] JUST;
            done;

         done;


         do /if cmp( $section_tbl, "table_body");

            do /if cmp( ROWSPAN, "1") and cmp ( colstart, "1");
               set $compute_line "on";
            done;

         done;


         do /if $just_broke_page;
			      put "{\pard\par}" NL;

            do /if ^VALUE and $first_row_after_break and cmp( $section_tbl, "table_body");

               do /if ^cmp( ROWSPAN, "1");
                  put $column_text[colstart ] /if $column_text[colstart];
               done;

            done;

         done;

      done;


      do /if URL;
         put "}}}";
         unset $url_flag;
      done;


      do /if $postimage_name;
         set $stream_name $postimage_name;
         putstream $stream_name;
         unset $postimage_name;
      done;


      do /if POSTIMAGE;
         set $stream_name POSTIMAGE;
         putstream $stream_name;
      done;


      do /if $tables_off;
         put "}" NL;

      else ;
	    *do /if $$pageno_tbl; *changed by bl delete this line to return to normal; 
         put "\cell}" NL ; *maybe here; 
		*done;*changed by bl delete this line to return to normal; 

      done;

      close;

      trigger cell_shape start /if ^$tables_off;

      do /if colend;
         eval $tmp_colend inputn(colend,"3.0");

      else;

         do /if colspan;
            eval $tmp_colspan inputn(colspan,"3.0");

         else;
            eval $tmp_colspan 1;
         done;

         eval $tmp_colstart inputn(colstart,"3.0");
         eval $tmp_colend $tmp_colstart + $tmp_colspan -1;
         unset $tmp_colspan;
         unset $tmp_colstart;
      done;

      eval $tmp_colcount inputn(colcount,"3.0");

      do /if $tmp_colend eq $tmp_colcount;
         set $saved_row_border_width OUTPUTWIDTH;
      done;

      unset $tmp_colcount;
      unset $tmp_colend;
   end;
   

   end;
run;
/*template to create prismrtf style for ods output to RTF*/
proc template;                                                                
   define style Styles.prismrtf;                                              
      parent = styles.printer; *parent is printer; 
/*set margins per CARA/Gloabl requirements*/ 
      style Body from Document                                                
         "def margins for landscape RTF style in PRISM" /                   
         marginleft = &lrmargin.in                                                   
         marginright = &lrmargin.in                                                  
         margintop = 1.0in                                                   
         marginbottom = 1.0in;              
/*set all fonts and font sizes*/ 
      style fonts /                                                           
         'BatchFixedFont' = ("Courier New",&fsize.pt)                                   
         'TitleFont2' = ("Courier New",&fsize.pt)                                       
         'TitleFont' = ("Courier New",&fsize.pt)                                        
         'StrongFont' = ("Courier New",&fsize.pt)                                       
         'EmphasisFont' = ("Courier New",&fsize.pt)                                     
         'FixedEmphasisFont' = ("Courier New",&fsize.pt)                                
         'FixedStrongFont' = ("Courier New",&fsize.pt)                                  
         'FixedHeadingFont' = ("Courier New",&fsize.pt)                                 
         'FixedFont' = ("Courier New",&fsize.pt)                                        
         'headingEmphasisFont' = ("Courier New",&fsize.pt)                              
         'headingFont' = ("Courier New",&fsize.pt)                                      
         'docFont' = ("Courier New",&fsize.pt);   

		 


 /*remove background color from headers and footers*/
		style header from HeadersAndFooters/
   		
		 backgroundcolor = white;


	
/*set table parameters, most important is hsides which puts lines at top and bottom of table*/ 
     style table from table /                                                
         frame = hsides   
         rules = groups                                                       
         fontfamily = "Courier New"                                               
         fontsize = &fsize.pt                                                       
         fontweight = medium                                                  
         fontwidth = extra_compressed                                         
         padding = 0.01pt  
		     cellpadding=0.02pt 
         borderspacing = 0.01pt    
         backgroundcolor = white 
         color = black;
/*set data parameters*/
      style data from data /                                                  
         fontfamily = "Courier New"                                              
         fontsize = &fsize.pt                                                       
         fontweight = medium                                                  
         fontwidth = normal                                                   
         padding = 0.01pt                                                            
         borderspacing = 0.1pt                                                
         backgroundcolor = white  
         color = black;

                                                             
               /*set parskip size to 10 so its same size as all other text even though missing*/
		 style parskip / fontsize=&fsize.pt;

 
/*this is used for using the "option number" in SAS in order to put page number at top and in header*/

%local specfs tit1_width subtit1_width subtit1_loc1 subtit2_loc2 subtit3_loc3;
%let specfs=%eval(2*&FSIZE);

		/* If default margin, which is 1.0 in, is used, make no change */
	%if &LRMARGIN=1.0 %then %do;
		style pageno from pageno / 
        /* This section is RTF code used to put &protocol left justified, &display centered, and Page and of Page Last Page in the header using the options number option*/
        %if "&Orientation"="LANDSCAPE" %then %do;
		 pretext="&ESCCHAR.R""{\header\pard\plain\qc{\trowd\trkeep\trqc\cltxlrtb\clvertalt\clcbpat8\clpadt10\clpadft3\clpadr10\clpadfr3\cellx4298\cltxlrtb\clvertalt\clcbpat8\clpadt10\clpadft3\clpadr10\clpadfr3\cellx8654\cltxlrtb\clvertalt\clcbpat8\clpadt10\clpadft3\clpadr10\clpadfr3\cellx12960\pard\plain\intbl\sb10\sa10\ql\f1\fs&specfs\cf1{Protocol: &protocol.\cell}\pard\plain\intbl\sb10\sa10\qc\f1\fs&specfs\cf1{&display\cell}\pard\plain\intbl\sb10\sa10\qr\f1\fs&specfs\cf1{Page }"""
			posttext="&ESCCHAR.R""\pard\plain\intbl\sb10\sa10\qr\f1\fs&specfs\cf1 { of {\field{\*\fldinst { NUMPAGES }}}\cell}{\row}}}"""
		 %str(;)
        %end;
        %else %if "&Orientation"="PORTRAIT" %then %do;
		 pretext="&ESCCHAR.R""{\header\pard\plain\qc{\trowd\trkeep\trqc\cltxlrtb\clvertalt\clcbpat8\clpadt10\clpadft3\clpadr10\clpadfr3\cellx3000\cltxlrtb\clvertalt\clcbpat8\clpadt10\clpadft3\clpadr10\clpadfr3\cellx6000\cltxlrtb\clvertalt\clcbpat8\clpadt10\clpadft3\clpadr10\clpadfr3\cellx9400\pard\plain\intbl\sb10\sa10\ql\f1\fs&specfs\cf1{Protocol: &protocol.\cell}\pard\plain\intbl\sb10\sa10\qc\f1\fs&specfs\cf1{&display\cell}\pard\plain\intbl\sb10\sa10\qr\f1\fs&specfs\cf1{Page }"""
			posttext="&ESCCHAR.R""\pard\plain\intbl\sb10\sa10\qr\f1\fs&specfs\cf1 { of {\field{\*\fldinst { NUMPAGES }}}\cell}{\row}}}"""
		 %str(;)
  %end;
    %end; %else %do;
        /* Handling defined L/R margins */
		style pageno from pageno / 
        %if "&Orientation"="LANDSCAPE" %then %do;
			%let tit1_width=%sysevalf(1440*(11 - 2*&LRMARGIN));
			%let subtit1_width=%sysevalf(&tit1_width/3, integer);
			%let subtit1_loc1=&subtit1_width;
			%let subtit1_loc2=%sysevalf(&subtit1_loc1 + &subtit1_width);
			%let subtit1_loc3=%sysevalf(&subtit1_loc2 + &subtit1_width);

/* 			%put subtit1_loc1=&subtit1_loc1; */
/* 			%put subtit1_loc2=&subtit1_loc2; */
/* 			%put subtit1_loc3=&subtit1_loc3; */
      	
		 	pretext="&ESCCHAR.R""{\header\pard\plain\qc{\trowd\trkeep\trqc\cltxlrtb\clvertalt\clcbpat8\clpadt10\clpadft3\clpadr10\clpadfr3\cellx&subtit1_loc1\cltxlrtb\clvertalt\clcbpat8\clpadt10\clpadft3\clpadr10\clpadfr3\cellx&subtit1_loc2\cltxlrtb\clvertalt\clcbpat8\clpadt10\clpadft3\clpadr10\clpadfr3\cellx&subtit1_loc3\pard\plain\intbl\sb10\sa10\ql\f1\fs&specfs\cf1{Protocol: &protocol.\cell}\pard\plain\intbl\sb10\sa10\qc\f1\fs&specfs\cf1{&display\cell}\pard\plain\intbl\sb10\sa10\qr\f1\fs&specfs\cf1{Page }"""
			posttext="&ESCCHAR.R""\pard\plain\intbl\sb10\sa10\qr\f1\fs&specfs\cf1 { of {\field{\*\fldinst { NUMPAGES }}}\cell}{\row}}}"""
		 %str(;)
		 
        %end;
        %else %if "&Orientation"="PORTRAIT" %then %do;
			%let tit1_width=%sysevalf(1440*(8.5 - 2*&LRMARGIN));
			%let subtit1_width=%sysevalf(&tit1_width/3, integer);
			%let subtit1_loc1=&subtit1_width;
			%let subtit1_loc2=%sysevalf(&subtit1_loc1 + &subtit1_width);
			%let subtit1_loc3=%sysevalf(&subtit1_loc2 + &subtit1_width);
/* 			 */
/* 			%put subtit1_loc1=&subtit1_loc1; */
/* 			%put subtit1_loc2=&subtit1_loc2; */
/* 			%put subtit1_loc3=&subtit1_loc3; */

		 	pretext="&ESCCHAR.R""{\header\pard\plain\qc{\trowd\trkeep\trqc\cltxlrtb\clvertalt\clcbpat8\clpadt10\clpadft3\clpadr10\clpadfr3\cellx&subtit1_loc1\cltxlrtb\clvertalt\clcbpat8\clpadt10\clpadft3\clpadr10\clpadfr3\cellx&subtit1_loc2\cltxlrtb\clvertalt\clcbpat8\clpadt10\clpadft3\clpadr10\clpadfr3\cellx&subtit1_loc3\pard\plain\intbl\sb10\sa10\ql\f1\fs&specfs\cf1{Protocol: &protocol.\cell}\pard\plain\intbl\sb10\sa10\qc\f1\fs&specfs\cf1{&display\cell}\pard\plain\intbl\sb10\sa10\qr\f1\fs&specfs\cf1{Page }"""
			posttext="&ESCCHAR.R""\pard\plain\intbl\sb10\sa10\qr\f1\fs&specfs\cf1 { of {\field{\*\fldinst { NUMPAGES }}}\cell}{\row}}}"""
		 %str(;)
        %end;    
    
    
    %end;
end; 
run;

%mend; 
