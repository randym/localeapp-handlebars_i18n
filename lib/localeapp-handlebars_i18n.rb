require 'localeapp'

# The Localeapp Module - we place HandlebarsI18n under this namespace
module Localeapp

  # A singleton module that reports missing translations found in handebars templates to Localeapp.
  # Once you have set everything up with configure it is a simple matter of calling Localeapp::HandlebarsI18n.send_missing_translations and you are done.
  module HandlebarsI18n

    class << self

      # configures HanldebarsI18n
      # @param [Object] output You can pass in an object that accepts calls to puts for logging. By default $stdout will be used.
      # @param [Proc] block A configuration block
      # @example
      #     Localeapp::HandlebarsI18.configure do |config|
      #       config.localeapp_api_key = ENV['LOCALEAPP_API_KEY']
      #       config.hbs_helper = 't'
      #       config.hbs_load_path = Dir[File.expand_path '../support/**.hbs', __FILE__]
      #       config.yml_load_path = File.expand_path '../support/', __FILE__
      #       config.default_locale = :ru
      #     end
      def configure(output = $stdout, &block)
        @output = output
        instance_eval &block if block_given?
        register_missing_translations
      end

      # The string name of your handlebars helper function for translation.
      # Here is an example coffeescript handlebars helper registration that creates a helper named 't'
      # that uses I18n-js for javascript localizations. If you had a helper like the one below, you would
      # pass 't' into this method. 't' is also the default so if you are already using a helper named 't'
      # you do not need to configure this.
      #
      # This helper is interpolated into the regular expression used to scan for translation keys:
      # "{{#{hbs_helper}} (.*?)}}"
      #
      # @example
      #   Handlebars.registerHelper 't', (key) ->
      #     safe I18n.t(key)
      # @param [String] helper The name of your handlebars helper used for localization.
      def hbs_helper=(helper)
        @hbs_helper
      end

      # @see hbs_helper=
      def hbs_helper
        @hbs_helper ||= 't'
      end

      # The default locale to load when comparing handlebar translation keys and I18n translation keys.
      # This is used when loading YAML data into I18n's simple backend
      # @param [Symbol] locale the locale to load.
      def default_locale=(locale)
        @default_locale = locale
      end

      # @see default_locale=
      def default_locale
        @default_locale ||= :en
      end

      # The directory where your locale .yml files live.
      # @param [String] dir The directory to search for the default locale's YAML data
      def yml_load_path=(dir)
        @yml_load_path = dir
      end

      # This defines the yml file to load for I18n. It retuns an interpolated string of the yml_load_path value you configured
      # and the default locale.
      # @return [String]
      def yml_load_path
        "#{@yml_load_path}/#{default_locale}.yml"
      end

      # Sets the array of handlebars templates that will be searched for localization helpers. Dir.glob is pretty dang handy here.
      # @param [Array] files The files to search.
      # @see hbs_helper
      def hbs_load_path=(files)
        @hbs_load_path = files.flatten
      end

      # Returns the files you specified or an empty array
      # @return [Array]
      def hbs_load_path
        @hbs_load_path ||= []
      end

      # Configures localeapp to use the api key you specify when reporting missing translations.
      # @param [String] api_key The localeapp api key.
      def localeapp_api_key=(api_key)
        Localeapp.configure do |config|
          config.api_key= api_key
        end
      end

      # Sends any missing translations to Localeapp.
      # @note If you have not configured Localeapp::HandlebarsI18n you will recieve an error with an example on how to do so.
      def send_missing_translations
        ensure_configured
        return if Localeapp.missing_translations[default_locale].empty?
        @output.puts "sending missing translations to localeapp"
        Localeapp::sender.post_missing_translations
      end

      private
      def hbs_locale_keys
        @hbs_locale_keys ||= hbs_load_path.map do |file| 
          extract_keys(file)
        end.flatten.compact.uniq
      end 


      def ensure_configured
        if @hbs_load_path.nil? || @yml_load_path.nil?
          raise ArgumentError, <<ERROR_MSG
          "You must configure Localeapp::Reporter before sending missing translations.
          example:

          Localeapp::Reporter.configure do |config|
            config.localeapp_api_key = ENV['LOCALEAPP_API_KEY']
            config.yml_load_path = 'locales/'
            config.hbs_load_path = 'assets/scripts/app/templates/**/*.hbs'
            config.hbs_helper = 't'
            config.default_locale = :en
          end
ERROR_MSG
        end
      end


      def matcher
        @matcher ||= Regexp.new("{{#{hbs_helper} (.*?)}}")
      end

      def backend
        @backend ||= I18n::Backend::Simple.new.tap do |simple|
          simple.load_translations yml_load_path
        end
      end

      def extract_keys(template_file)
        template = IO.read(template_file)
        template.scan(matcher)
      end

      def register_missing_translations 
        hbs_locale_keys.each do |key|
          key.gsub!(/[\"\']/, '')
          begin
            backend.translate(default_locale, key)
          rescue Exception => e
            @output.puts "translation missing: #{key}"
            Localeapp.missing_translations.add(default_locale, key, key.split('.').last)
          end
        end
      end
    end
  end
end


