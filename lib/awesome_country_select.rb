module ActionView
  module Helpers
    module FormOptionsHelper
      # Return select and option tags for the given object and method, using 
      # +country_options_for_select+ to generate the list of option tags.
      # This method isn't backward compatible, it has additional +removed_countries+
      # param which should keeps information about already selected options. 
      #
      # == Examples
      #
      # Simple country select:
      #   country_select :user, :country_name
      #  
      # List with additional countries at the top:
      #   country_select :user, :country_name, [['My additional country', 'COUNTRY_CODE']]
      #  
      # List with removed elements (eg. which are already used):
      #   country_select :user, :country_name, nil, %w{EN PL DK} 
      # 
      # List with "Rest of world" region:
      #   country_select :user, :country_name, nil, nil, :rest_of_world => true
      #  
      # List with special regions for each continent:
      #   country_select :user, :country_name, nil, nil, :world_regions => true
      #
      # Country labels in native language, english or both:
      #  country_select :user, :country_name, nil, nil, :labels => :english # default
      #  country_select :user, :country_name, nil, nil, :labels => :native  # eg. "Україна", "Polska", etc.
      #  country_select :user, :country_name, nil, nil, :labels => :both    # eg. "Ukraine - Україна"
      def country_select(object, method, priority_countries=nil, removed_countries=nil, 
        options={}, html_options={})
        tag = InstanceTag.new(object, method, self, options.delete(:object))
        tag.to_country_select_tag(priority_countries, removed_countries, options, 
          html_options)
      end

      # Returns a string of option tags for pretty much any country in the world. 
      # Supply a country code as +selected+ to have it marked as the selected option 
      # tag. You can also supply an array of countries as +priority_countries+, so
      # that they will be listed above the rest of the (long) list. Also you can 
      # specify options which should be excluded from select (eg. options which are
      # already selected, etc) in +removed_countries+. Finally, there is +labels+
      # parameter, which can be :english (used by default), :both or :native. 
      # This option allows to display native or english country name (or both of course). 
      #
      # NOTE: Only the option tags are returned, you have to wrap this call in 
      # a regular HTML select tag.
      def country_options_for_select(selected=nil, priority_countries=nil, removed_countries=nil, 
        world_regions=false, rest_of_world=false, labels=:english)
        result = ""
        country_codes = ISO3166::Countries::CODES
        
        if removed_countries
          priority_countries -= removed_countries if priority_countries
          country_codes -= removed_countries
        end

        countries = country_codes.map! {|code| [country_name(code, labels), code] }
        countries.sort! {|a,b| a[0]<=>b[0]}

        if priority_countries && priority_countries.class == Array
          result += options_for_select(priority_countries, selected)
        end

        result += rest_of_world_options_for_select(removed_countries || []) if rest_of_world
        result += world_regions_options_for_select(removed_countries || []) if world_regions
        
        unless result.empty?
          result += "<option value=\"\" disabled=\"disabled\">-------------</option>\n"
        end
        
        result += options_for_select(countries, selected)
      end
    
      # Returns country name for specified code.
      def country_name(code, labels=nil)
        if code.size > 2
          case code
          when 'EUC'
            return I18n.t('helpers.world_regions.european')
          when 'NAC'
            return I18n.t('helpers.world_regions.north_american')
          when 'SAC'
            return I18n.t('helpers.world_regions.south_american')
          when 'ASC'
            return I18n.t('helpers.world_regions.asian')
          when 'AFC'
            return I18n.t('helpers.world_regions.african')
          when 'OCC'
            return I18n.t('helpers.world_regions.oceania')
          when 'ROW'
            return I18n.t('helpers.rest_of_world')
          end
        elsif labels == :both
          ISO3166::Countries::COUNTRIES[code].join(' / ')
        elsif labels == :native
          ISO3166::Countries::COUNTRIES[code][1] || ISO3166::Countries::COUNTRIES[code][0]
        else
          ISO3166::Countries::COUNTRIES[code][0]
        end
      end

      protected
      
      # It returns +original+ array without options which are specified 
      # in +removed_options+.  
      def remove_options(original, removed_options)
        if (removed_options && removed_options.class == Array && original && original.class == Array)
          return original-removed_options
        end 
        original
      end 
      
      # Returns a string of option tags for world regions like _Nort America_, 
      # _European_ countries, etc.
      def world_regions_options_for_select(removed_countries)
        result = ""
        euc = remove_options(ISO3166::Countries::EUROPE, removed_countries)
        nac = remove_options(ISO3166::Countries::NORTH_AMERICA, removed_countries)
        sac = remove_options(ISO3166::Countries::SOUTH_AMERICA, removed_countries)        
        asc = remove_options(ISO3166::Countries::ASIA, removed_countries)
        afc = remove_options(ISO3166::Countries::AFRICA, removed_countries)
        occ = remove_options(ISO3166::Countries::OCEANIA, removed_countries)
        result += options_for_select([[I18n.t('helpers.world_regions.european'), 'EUC']]) if !euc.empty? && !removed_countries.include?('EUC')
        result += options_for_select([[I18n.t('helpers.world_regions.north_american'), 'NAC']]) if !nac.empty? && !removed_countries.include?('NAC')
        result += options_for_select([[I18n.t('helpers.world_regions.south_american'), 'SAC']]) if !sac.empty? && !removed_countries.include?('SAC')
        result += options_for_select([[I18n.t('helpers.world_regions.asian'), 'ASC']]) if !asc.empty? && !removed_countries.include?('ASC')
        result += options_for_select([[I18n.t('helpers.world_regions.african'), 'AFC']]) if !afc.empty? && !removed_countries.include?('AFC')
        result += options_for_select([[I18n.t('helpers.world_regions.oceania'), 'OCC']]) if !occ.empty? && !removed_countries.include?('OCC')
      end
      
      # Returns a string of option tags for _rest of world_.
      def rest_of_world_options_for_select(removed_countries)
        if removed_countries && !removed_countries.include?('ROW')
          options_for_select([[I18n.t('helpers.rest_of_world'), 'ROW']])
        end.to_s
      end
    end
    
    class InstanceTag
      def to_country_select_tag(priority_countries, removed_countries, options, html_options)
        html_options = html_options.stringify_keys
        add_default_name_and_id(html_options)
        value = value(object)
        content_tag("select",
          add_options(
            country_options_for_select(value, priority_countries, removed_countries, 
              options.delete(:world_regions), options.delete(:rest_of_world), options.delete(:label)), 
              options, value
          ), html_options
        )
      end
    end
    
    class FormBuilder
      def country_select(method, priority_countries=nil, removed_countries=nil, 
        options={}, html_options={})
        @template.country_select(@object_name, method, priority_countries, 
          removed_countries, options.merge(:object => @object), html_options)
      end
    end
  end
end

module ISO3166
  module Countries
    COUNTRIES = {
      "VA" => ["Holy See (Vatican City State)", nil],
      "CC" => ["Cocos (Keeling) Islands", nil],
      "GT" => ["Guatemala", nil],
      "JP" => ["Japan", "日本"],
      "SE" => ["Sweden", "Sverige"],
      "TZ" => ["Tanzania, United Republic of", nil],
      "CD" => ["Congo, the Democratic Republic of the", nil],
      "GU" => ["Guam", "Guåhan"],
      "MM" => ["Myanmar", nil],
      "DZ" => ["Algeria", "الجزائر"],
      "MN" => ["Mongolia", "Монгол Улс"],
      "PK" => ["Pakistan", "پاکستان"],
      "SG" => ["Singapore", "சிங்கப்பூர்"],
      "VC" => ["Saint Vincent and the Grenadines", nil],
      "CF" => ["Central African Republic", "Ködörösêse tî Bêafrîka"],
      "GW" => ["Guinea-Bissau", "Guiné-Bissau"],
      "MO" => ["Macao", nil],
      "PL" => ["Poland", "Polska"],
      "SH" => ["Saint Helena", nil],
      "CG" => ["Congo", nil],
      "MP" => ["Northern Mariana Islands", nil],
      "PM" => ["Saint Pierre and Miquelon", "Saint-Pierre-et-Miquelon"],
      "SI" => ["Slovenia", "Slovenija"],
      "VE" => ["Venezuela", nil],
      "ZW" => ["Zimbabwe", nil],
      "CH" => ["Switzerland", "Schweiz"],
      "GY" => ["Guyana", nil],
      "MQ" => ["Martinique", nil],
      "PN" => ["Pitcairn", nil],
      "SJ" => ["Svalbard and Jan Mayen", nil],
      "CI" => ["Cote D'ivoire", nil],
      "MR" => ["Mauritania", "Mauritanie"],
      "SK" => ["Slovakia", "Slovensko"],
      "VG" => ["Virgin Islands, British", nil],
      "MS" => ["Montserrat", nil],
      "SL" => ["Sierra Leone", "Serra Leoa"],
      "CK" => ["Cook Islands", "Kūki 'Āirani"],
      "ID" => ["Indonesia", nil],
      "MT" => ["Malta", nil],
      "SM" => ["San Marino", nil],
      "VI" => ["Virgin Islands, U.S.", nil],
      "YE" => ["Yemen", "اليمن"],
      "CL" => ["Chile", "Chile"],
      "IE" => ["Ireland", "Éireann"],
      "LA" => ["Lao People's Democratic Republic", nil],
      "MU" => ["Mauritius", "Maurice"],
      "SN" => ["Senegal", "Sénégal"],
      "CM" => ["Cameroon", nil],
      "FI" => ["Finland", nil],
      "LB" => ["Lebanon", "لبنان"],
      "MV" => ["Maldives", "ގުޖޭއްރާ ޔާއްރިހޫމްޖު"],
      "PR" => ["Puerto Rico", nil],
      "SO" => ["Somalia", "As-Sūmāl"],
      "CN" => ["China", "چین"],
      "FJ" => ["Fiji", "Viti"],
      "LC" => ["Saint Lucia", nil],
      "MW" => ["Malawi", nil],
      "PS" => ["Palestinian Territory, Occupied", nil],
      "CO" => ["Colombia", nil],
      "FK" => ["Falkland Islands (Malvinas)", nil],
      "MX" => ["Mexico", "México"],
      "PT" => ["Portugal", nil],
      "MY" => ["Malaysia", nil],
      "SR" => ["Suriname", nil],
      "VN" => ["Viet Nam", nil],
      "FM" => ["Micronesia, Federated States of", nil],
      "MZ" => ["Mozambique", "Moçambique"],
      "CR" => ["Costa Rica", nil],
      "PW" => ["Palau", "Belau"],
      "CS" => ["Serbia and Montenegro", nil],
      "FO" => ["Faroe Islands", "Færøerne"],
      "ST" => ["Sao Tome and Principe", nil],
      "IL" => ["Israel", "ישראל"],
      "LI" => ["Liechtenstein", nil],
      "PY" => ["Paraguay", "Paraguái"],
      "BA" => ["Bosnia and Herzegovina", "Bosna i Hercegovina"],
      "CU" => ["Cuba", nil],
      "IM" => ["Isle of Man", "Ellan Vannin"],
      "SV" => ["El Salvador", nil],
      "CV" => ["Cape Verde", "Cabo Verde"],
      "FR" => ["France", nil],
      "IN" => ["India", "भारत"],
      "LK" => ["Sri Lanka", "இலங்கை"],
      "BB" => ["Barbados", nil],
      "IO" => ["British Indian Ocean Territory", nil],
      "VU" => ["Vanuatu", nil],
      "CX" => ["Christmas Island", nil],
      "RE" => ["Reunion", nil],
      "UA" => ["Ukraine", "Україна"],
      "SY" => ["Syrian Arab Republic", nil],
      "CY" => ["Cyprus", "Kıbrıs"],
      "IQ" => ["Iraq", "العراق"],
      "SZ" => ["Swaziland", "Swatini"],
      "BD" => ["Bangladesh", "বাংলাদেশ"],
      "CZ" => ["Czech Republic", "Česká republika or Česko"],
      "IR" => ["Iran, Islamic Republic of", nil],
      "YT" => ["Mayotte", nil],
      "BE" => ["Belgium", "België"],
      "IS" => ["Iceland", "Ísland"],
      "BF" => ["Burkina Faso", nil],
      "EC" => ["Ecuador", nil],
      "IT" => ["Italy", nil],
      "OM" => ["Oman", "عمان"],
      "BG" => ["Bulgaria", "България"],
      "BH" => ["Bahrain", "البحرين"],
      "LR" => ["Liberia", nil],
      "UG" => ["Uganda", nil],
      "BI" => ["Burundi", nil],
      "EE" => ["Estonia", "Eesti"],
      "LS" => ["Lesotho", nil],
      "BJ" => ["Benin", "Bénin"],
      "LT" => ["Lithuania", "Lietuva"],
      "EG" => ["Egypt", "مصر"],
      "EH" => ["Western Sahara", nil],
      "LU" => ["Luxembourg", "Lëtzebuerg"],
      "RO" => ["Romania", "România"],
      "BM" => ["Bermuda", "Bermuda"],
      "LV" => ["Latvia", "Latvija"],
      "BN" => ["Brunei Darussalam", nil],
      "UM" => ["United States Minor Outlying Islands  ", nil],
      "BO" => ["Bolivia", nil],
      "KE" => ["Kenya", nil],
      "NA" => ["Namibia", nil],
      "LY" => ["Libyan Arab Jamahiriya", nil],
      "BR" => ["Brazil", "Brasil"],
      "KG" => ["Kyrgyzstan", "Киргизия"],
      "NC" => ["New Caledonia", "Nouvelle-Calédonie"],
      "BS" => ["Bahamas", nil],
      "HK" => ["Hong Kong", "香港"],
      "KH" => ["Cambodia", nil],
      "BT" => ["Bhutan", nil],
      "KI" => ["Kiribati", nil],
      "NE" => ["Niger", nil],
      "QA" => ["Qatar", "قطر"],
      "RU" => ["Russian Federation", nil],
      "HM" => ["Heard Island and Mcdonald Islands", nil],
      "NF" => ["Norfolk Island", nil],
      "US" => ["United States", nil],
      "BV" => ["Bouvet Island", nil],
      "ER" => ["Eritrea", "Ertra"],
      "HN" => ["Honduras", nil],
      "NG" => ["Nigeria", nil],
      "RW" => ["Rwanda", nil],
      "BW" => ["Botswana", nil],
      "ES" => ["Spain", "Espainia"],
      "ET" => ["Ethiopia", "Etiopia"],
      "NI" => ["Nicaragua", nil],
      "AD" => ["Andorra", nil],
      "BY" => ["Belarus", "Беларусь"],
      "KM" => ["Comoros", "Comores"],
      "AE" => ["United Arab Emirates", "الإمارات العربيّة المتّحدة"],
      "BZ" => ["Belize", nil],
      "HR" => ["Croatia", "Hrvatska"],
      "KN" => ["Saint Kitts and Nevis", nil],
      "TC" => ["Turks and Caicos Islands", nil],
      "AF" => ["Afghanistan", "افغانستان"],
      "NL" => ["Netherlands", nil],
      "TD" => ["Chad", "تشاد"],
      "AG" => ["Antigua and Barbuda", nil],
      "HT" => ["Haiti", "Ayiti"],
      "KP" => ["Korea, Democratic People's Republic of", nil],
      "UY" => ["Uruguay", nil],
      "GA" => ["Gabon", nil],
      "HU" => ["Hungary", "Magyarország"],
      "TF" => ["French Southern Territories", nil],
      "UZ" => ["Uzbekistan", "Ўзбекистон"],
      "AI" => ["Anguilla", nil],
      "DE" => ["Germany", "Deutschland"],
      "GB" => ["United Kingdom", nil],
      "KR" => ["Korea, Republic of", nil],
      "TG" => ["Togo", nil],
      "NO" => ["Norway", "Norge"],
      "TH" => ["Thailand", "ประเทศไทย"],
      "GD" => ["Grenada", nil],
      "NP" => ["Nepal", "नेपाल"],
      "ZA" => ["South Africa", "Mzantsi Afrika"],
      "AL" => ["Albania", "Shqipëria"],
      "GE" => ["Georgia", "საქართველო"],
      "TJ" => ["Tajikistan", "Тоҷикистон"],
      "WF" => ["Wallis and Futuna", nil],
      "AM" => ["Armenia", "Հայաստան"],
      "GF" => ["French Guiana", nil],
      "NR" => ["Nauru", "Naoero"],
      "TK" => ["Tokelau", nil],
      "AN" => ["Netherlands Antilles", "Nederlandse Antillen"],
      "DJ" => ["Djibouti", nil],
      "KW" => ["Kuwait", "الكويت"],
      "TL" => ["Timor-Leste", nil],
      "AO" => ["Angola", nil],
      "DK" => ["Denmark", nil],
      "GG" => ["Guernsey", nil],
      "TM" => ["Turkmenistan", "Türkmenistan"],
      "GH" => ["Ghana", nil],
      "JE" => ["Jersey", "Jèrri"],
      "MA" => ["Morocco", "المغرب"],
      "KY" => ["Cayman Islands", nil],
      "NU" => ["Niue", nil],
      "TN" => ["Tunisia", "تونس"],
      "DM" => ["Dominica", nil],
      "GI" => ["Gibraltar", nil],
      "KZ" => ["Kazakhstan", "Қазақстан"],
      "TO" => ["Tonga", nil],
      "AQ" => ["Antarctica", nil],
      "MC" => ["Monaco", nil],
      "AR" => ["Argentina", nil],
      "MD" => ["Moldova, Republic of", nil],
      "AS" => ["American Samoa", nil],
      "DO" => ["Dominican Republic", "República Dominicana"],
      "PA" => ["Panama", "Panamá"],
      "TR" => ["Turkey", "Türkiye"],
      "AT" => ["Austria", "Österreich"],
      "GL" => ["Greenland", "Grønland"],
      "NZ" => ["New Zealand", "Aotearoa"],
      "AU" => ["Australia"],
      "GM" => ["Gambia", nil],
      "MG" => ["Madagascar", nil],
      "GN" => ["Guinea", "Guinée"],
      "MH" => ["Marshall Islands", nil],
      "TT" => ["Trinidad and Tobago", nil],
      "ZM" => ["Zambia", nil],
      "AW" => ["Aruba", nil],
      "PE" => ["Peru", "Perú"],
      "SA" => ["Saudi Arabia", "المملكة العربية السعودية"],
      "AX" => ["Aland Islands", nil],
      "GP" => ["Guadeloupe", nil],
      "JM" => ["Jamaica", nil],
      "PF" => ["French Polynesia", "Polynésie Française"],
      "SB" => ["Solomon Islands", nil],
      "TV" => ["Tuvalu", nil],
      "WS" => ["Samoa", nil],
      "CA" => ["Canada", nil],
      "GQ" => ["Equatorial Guinea", nil],
      "SC" => ["Seychelles", "Sesel"],
      "TW" => ["Taiwan, Province of China", nil],
      "AZ" => ["Azerbaijan", "Azərbaycan"],
      "GR" => ["Greece", "Ελλάδα"],
      "MK" => ["Macedonia, the Former Yugoslav Republic of", nil],
      "PG" => ["Papua New Guinea", "Papua Niugini"],
      "GS" => ["South Georgia and the South Sandwich Islands", nil],
      "SD" => ["Sudan", "السودان"],
      "JO" => ["Jordan", "الاردن"],
      "ML" => ["Mali", nil],
      "PH" => ["Philippines", "El Filipinas"],
      }
      
    CODES              = COUNTRIES.map{|code, country| code}
    NAMES              = COUNTRIES.map{|code, country| country}
    
    EUROPE         = %W(AX AL AD AT BY BE BA BG HR CZ DK EE FO FI FR DE GI GR GG 
                        VA HU IS IE IM IT JE LV LI LT LU MK MT MD MC ME NL NO PL 
                        PT RO RU SM RS SK SI ES SJ SE CH UA GB
                        ) 
    NORTH_AMERICA  = %W(AI AG AW BS BB BZ BM VG CA KY CR CU DM DO SV GL GD GP GT 
                        HT HN JM MQ MX MS AN NI PA PR BL KN LC MF PM VC TT TC US 
                        VI
                        ) 
    SOUTH_AMERICA  = %W(AR BO BR CL CO EC FK GF GY PY PE SR UY VE) 
    ASIA           = %W(AF AM AZ BH BD BT IO BN KH CN CX CC CY GE HK IN ID IR IQ 
                        IL JP JO KZ KP KR KW KG LA LB MO MY MV MN MM NP OM PK PS 
                        PH QA SA SG LK SY TW TJ TH TL TR TM AE UZ VN YE
                        )
    AFRICA         = %W(DZ AO BJ BW BF BI CM CV CF TD KM CD CG CI DJ EG GQ ER ET  
                        GA GM GH GN GW KE LS LR LY MG MW ML MR MU YT MA MZ NA NE 
                        NG RE RW SH ST SN SC SL SO ZA SD SZ TZ TG TN UG EH ZM ZW
                        ) 
    OCEANIA        = %W(AS AU CK FJ PF GU KI MH FM NR NC NZ NU NF MP PW PG PN WS 
                        SB TK TO TV UM VU WF
                        )
  end
end
