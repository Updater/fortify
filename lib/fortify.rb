require 'active_record'
require 'active_support/core_ext'
require 'active_support/concern'

require 'fortify/version'
require 'fortify/base'
require 'fortify/controller'
require 'fortify/activerecord/base'
require 'fortify/activerecord/validation'
require 'fortify/activerecord/default_scope'

module Fortify
  thread_mattr_accessor :user, instance_accessor: false
  thread_mattr_accessor :enabled, instance_accessor: false

  class Error < StandardError; end
  class NotAuthorizedError < Error; end
  class InvalidUserError < Error; end
  class MissingPolicyError < Error; end

  class << self
    def enabled!
      self.enabled = true
    end

    def disabled!
      self.enabled = false
    end

    def enabled?
      self.enabled == true
    end

    def insecurely
      prior_enabled_state = self.enabled
      self.enabled = false
      yield
    ensure
      self.enabled = prior_enabled_state
    end

    def securely
      prior_enabled_state = self.enabled
      self.enabled = true
      yield
    ensure
      self.enabled = prior_enabled_state
    end
  end
end

ActiveSupport.on_load(:active_record) do
  def self.set_fortify(options={})
    include Fortify::ActiveRecord::Base
    include Fortify::ActiveRecord::Validation
    include Fortify::ActiveRecord::DefaultScope if options[:default_scope] == true
    if options[:policy]
      define_singleton_method :policy_class do
        "#{options[:policy]}".constantize
      end
    end
  end
end
