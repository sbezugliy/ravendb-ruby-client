require "active_support/concern"

class RavenExecutorTest
  def self.setup(context, _example)
    context.class_eval do
      include CreateExecutor
    end
  end

  def self.teardown(context, example)
  end

  module CreateExecutor
    extend ActiveSupport::Concern

    included do
      let :conventions do
        RavenDB::DocumentConventions.new
      end

      let :executor do
        create_executor
      end

      def create_executor(initial_urls: store.urls, database_name: store.database)
        RavenDB::RequestExecutor.new(initial_urls:,
                                     database_name:,
                                     conventions:,
                                     auth_options: store.auth_options)
      end
    end
  end
end
