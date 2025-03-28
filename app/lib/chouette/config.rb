# frozen_string_literal: true

module Chouette
  # Provides all configuration attributes
  class Config
    class Error < StandardError; end

    class << self
      def load
        if ENV['SKIP_CONFIG'] == 'true'
          puts 'Skip config loading'
          return
        end

        @instance = Config.new.tap do |config|
          # config.log if config.production?
        end
      end

      attr_reader :instance

      def loaded?
        @instance.present?
      end

      def method_missing(name, *arguments)
        return instance.send name, *arguments if instance && instance.respond_to?(name)

        super
      end
    end

    def initialize(environment = ENV)
      @env = Environment.new(environment)
    end

    def subscription
      @subscription ||= Subscription.new(env)
    end

    def mailer
      @mailer ||= Mailer.new(env)
    end

    def referential_additional_constraints?
      env.boolean('REFERENTIAL_ADDITIONAL_CONSTRAINTS', default: true)
    end

    # See Feature.additionals
    def additional_features
      @additional_features ||= env.array('FEATURES_ADDITIONAL')
    end

    class Subscription
      def initialize(env)
        @env = env
      end
      attr_reader :env

      def enabled?
        env.boolean('ACCEPT_USER_CREATION') ||
          env.boolean('SUBSCRIPTION_ENABLED') ||
          default_enabled?
      end

      def default_enabled?
        # FIXME: Many factories/specs don't support an enabled subscription
        !env.production? && !env.test?
      end

      def notification_recipients
        env.array('SUBSCRIPTION_NOTIFICATION_RECIPIENTS')
      end
    end

    class Mailer
      def initialize(env)
        @env = env
      end
      attr_reader :env

      def subject_prefix
        env.string('MAILER_SUBJECT_PREFIX')
      end

      def from
        return TEST_FROM if env.test?

        env.string('MAILER_FROM') || env.string('MAIL_FROM')
      end
    end

    def unsplash
      @unsplash ||= Unsplash.new(env)
    end

    class OAuthCredential
      attr_accessor :access_key, :secret_key

      def initialize(access_key:, secret_key:)
        @access_key = access_key
        @secret_key = secret_key
      end

      def present?
        [access_key, secret_key].all?(&:present?)
      end
    end

    class Unsplash
      def initialize(env)
        @env = env
      end
      attr_reader :env

      def credential
        @credential ||= OAuthCredential.new(
          access_key: env.string('UNSPLASH_ACCESS_KEY'),
          secret_key: env.string('UNSPLASH_SECRET_KEY')
        ).presence
      end

      def utm_source
        @utm_source ||= env.string('UNSPLASH_UTM_SOURCE') || 'chouette'
      end
    end

    class Environment
      def initialize(values = ENV)
        @values = values
      end

      delegate :development?, :test?, :production?, to: :rails_env

      def rails_env
        # Do not use Rails.env to simplify tests
        @rails_env ||= ActiveSupport::StringInquirer.new(value('RAILS_ENV') || 'development')
      end

      def value(name)
        @values["CHOUETTE_#{name}"] || @values[name]
      end

      def string(name)
        raw_value = value(name)
        return nil unless raw_value.present?

        raw_value.strip
      end

      BOOLEAN_TRUE_VALUES = %w[true 1].freeze
      BOOLEAN_FALSE_VALUES = %w[false 0].freeze

      def boolean(name, default: false)
        raw_value = value(name)
        return default unless raw_value

        raw_value = raw_value.downcase

        if default
          !BOOLEAN_FALSE_VALUES.include? raw_value
        else
          BOOLEAN_TRUE_VALUES.include? raw_value
        end
      end

      def array(name)
        raw_value = value(name)
        return [] unless raw_value

        raw_value.split(',')
      end
    end

    private

    attr_reader :env
  end
end
