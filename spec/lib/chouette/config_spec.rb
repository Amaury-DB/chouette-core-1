# frozen_string_literal: true

RSpec.describe Chouette::Config do
  let(:environment) { { 'RAILS_ENV' => 'test' } }
  let(:config) { Chouette::Config.new environment }

  def self.with_rails_env(rails_env, &block)
    context "in #{rails_env}" do
      before { environment['RAILS_ENV'] = rails_env.to_s }
      class_exec(&block)
    end
  end

  def self.with_env(env, &block)
    description = env.map { |k, v| "#{k} is '#{v}'" }.to_sentence
    context "when #{description}" do
      before { env.each { |k, v| environment[k.to_s] = v.to_s } }
      class_exec(&block)
    end
  end

  describe '#subscriotion' do
    subject(:subscription) { config.subscription }

    describe '#enabled?' do
      subject { subscription.enabled? }

      with_rails_env :development do
        it { is_expected.to be_truthy }
      end

      with_rails_env :test do
        it { is_expected.to be_falsy }
      end

      with_rails_env :production do
        it { is_expected.to be_falsy }

        with_env ACCEPT_USER_CREATION: 'true' do
          it { is_expected.to be_truthy }
        end

        with_env CHOUETTE_SUBSCRIPTION_ENABLED: 'true' do
          it { is_expected.to be_truthy }
        end

        with_env CHOUETTE_SUBSCRIPTION_ENABLED: 'false' do
          it { is_expected.to be_falsy }
        end
      end
    end

    describe '#notification_recipients' do
      subject { subscription.notification_recipients }

      it { is_expected.to eq([]) }

      with_env CHOUETTE_SUBSCRIPTION_NOTIFICATION_RECIPIENTS: 'foo@example.com' do
        it { is_expected.to contain_exactly('foo@example.com') }
      end

      with_env CHOUETTE_SUBSCRIPTION_NOTIFICATION_RECIPIENTS: 'foo@example.com,bar@example.com' do
        it { is_expected.to contain_exactly('foo@example.com', 'bar@example.com') }
      end
    end
  end

  describe '#unsplash' do
    subject(:unsplash) { config.unsplash }

    describe '#credential' do
      subject { unsplash.credential }

      with_env UNSPLASH_ACCESS_KEY: '' do
        it { is_expected.to be_nil }
      end

      with_env UNSPLASH_SECRET_KEY: '' do
        it { is_expected.to be_nil }
      end

      with_env UNSPLASH_ACCESS_KEY: 'dummy', UNSPLASH_SECRET_KEY: 'secret' do
        it { is_expected.to have_attributes(access_key: 'dummy', secret_key: 'secret') }
      end
    end

    describe '#utm_source' do
      subject { unsplash.utm_source }

      with_env UNSPLASH_UTM_SOURCE: '' do
        it { is_expected.to eq('chouette') }
      end

      with_env UNSPLASH_UTM_SOURCE: 'dummy' do
        it { is_expected.to eq('dummy') }
      end
    end
  end
end

RSpec.describe Chouette::Config::Environment do
  subject(:environment) { described_class.new(raw_env) }

  let(:raw_env) { {} }

  def self.with_env(env, &block)
    description = env.map { |k, v| "#{k} is '#{v}'" }.to_sentence
    context "when #{description}" do
      before { env.each { |k, v| raw_env[k.to_s] = v.to_s } }
      class_exec(&block)
    end
  end

  describe '.boolean' do
    context 'for name "DUMMY" without default' do
      subject { environment.boolean('DUMMY') }

      it { is_expected.to be_falsy }

      with_env CHOUETTE_DUMMY: 'true' do
        it { is_expected.to be_truthy }
      end

      with_env CHOUETTE_DUMMY: '1' do
        it { is_expected.to be_truthy }
      end

      with_env CHOUETTE_DUMMY: 'false' do
        it { is_expected.to be_falsy }
      end

      with_env CHOUETTE_DUMMY: '0' do
        it { is_expected.to be_falsy }
      end
    end

    context 'for name "DUMMY" without default true' do
      subject { environment.boolean('DUMMY', default: true) }

      it { is_expected.to be_truthy }

      with_env CHOUETTE_DUMMY: 'true' do
        it { is_expected.to be_truthy }
      end

      with_env CHOUETTE_DUMMY: 'false' do
        it { is_expected.to be_falsy }
      end
    end

    context 'for name "DUMMY" without default false' do
      subject { environment.boolean('DUMMY', default: false) }

      it { is_expected.to be_falsy }

      with_env CHOUETTE_DUMMY: 'true' do
        it { is_expected.to be_truthy }
      end

      with_env CHOUETTE_DUMMY: 'false' do
        it { is_expected.to be_falsy }
      end
    end
  end
end
