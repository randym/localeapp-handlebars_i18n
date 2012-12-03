require 'spec_helper'
require 'localeapp-handlebars_i18n'

describe Localeapp::HandlebarsI18n do
  class Log
    class << self
      def data
        @data ||= []
      end
      def puts(text)
        data << text
      end
    end
  end
  let(:reporter) {
    cloned_module = Localeapp::HandlebarsI18n.clone
    cloned_module.configure(Log) do |config|
      config.localeapp_api_key = 'whatever'
      config.hbs_helper = 't'
      config.hbs_load_path = Dir[File.expand_path '../support/**.hbs', __FILE__]
      config.yml_load_path = File.expand_path '../support/', __FILE__
      config.default_locale = :ru
    end
    cloned_module
  }
  before :each do
    reporter
  end

  context "with a configured localeapp reporter" do

    it 'configured the default locale' do
      reporter.default_locale.should == :ru
    end

    it 'configured the yml_load_path' do
      reporter.yml_load_path.should == File.expand_path("../support/#{reporter.default_locale}.yml", __FILE__)
    end

    it 'configured the hbs_load_path' do
      reporter.hbs_load_path.should == Dir[File.expand_path '../support/**.hbs', __FILE__]
    end

    it 'loaded up the i18n backend' do
      expect { reporter.send(:backend).translate(reporter.default_locale, 'existing.key') }.to_not raise_error(ArgumentError)
      expect { reporter.send(:backend).translate(reporter.default_locale, 'missing.key') }.to raise_error(ArgumentError)
    end

    it "configured Localeapp.missing_translations" do
      Localeapp.missing_translations.should_not be_nil
    end
    it "adds missing {{t missing.key}} translation key to Localeapp.missing_translations" do
      Localeapp.missing_translations[reporter.default_locale].should include('missing.key')
    end
  end

  context "when sending missing translations" do
    it 'executes a rest client request with the translations in the payload' do 
      RestClient::Request.should_receive(:execute).with(hash_including(
        :payload => { :translations => Localeapp.missing_translations.to_send }.to_json)).and_return(double('response', :code => 200))
        reporter.send_missing_translations
    end 
    it 'populates the log' do
      # something tells me that if I randomize the order of these specs,
      # this wont pass until a call to send_missing_translations gets
      # sent
      Log.data.should include('sending missing translations to localeapp')
    end
  end
  context "when nothing is configured" do
    before :each do
      @cloned_module = Localeapp::HandlebarsI18n.clone
    end

    it "send_missing_translations fails with a message to configure." do
      expect { @cloned_module.send_missing_translations }.to raise_error ArgumentError
    end
  end
end
