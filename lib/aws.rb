module Aws

  # @api private
  GEM_ROOT = File.dirname(File.dirname(__FILE__))

  @config = {}

  autoload :Credentials, 'aws/credentials'
  autoload :Errors, 'aws/errors'
  autoload :ErrorHandler, 'aws/error_handler'
  autoload :RequestHandler, 'aws/request_handler'
  autoload :ResponseHandler, 'aws/response_handler'
  autoload :Service, 'aws/service'
  autoload :Structure, 'aws/structure'
  autoload :TimestampFormatter, 'aws/timestamp_formatter'
  autoload :Util, 'aws/util'
  autoload :VERSION, 'aws/version'

  # @api private
  module Api
    autoload :BaseTranslator, 'aws/api/base_translator'
    autoload :Documentor, 'aws/api/documentor'
    autoload :DocExample, 'aws/api/doc_example'
    autoload :InputShapeTranslator, 'aws/api/shape_translator'
    autoload :OperationTranslator, 'aws/api/operation_translator'
    autoload :OutputShapeTranslator, 'aws/api/shape_translator'
    autoload :ServiceNamer, 'aws/api/service_namer'
    autoload :ShapeTranslator, 'aws/api/shape_translator'
    autoload :Translator, 'aws/api/translator'
    autoload :Visitor, 'aws/api/visitor'

    module ServiceTranslators
      autoload :CloudFront, 'aws/api/service_translators/cloud_front'
      autoload :DynamoDB, 'aws/api/service_translators/dynamo_db'
      autoload :Glacier, 'aws/api/service_translators/glacier'
      autoload :ImportExport, 'aws/api/service_translators/import_export'
      autoload :Route53, 'aws/api/service_translators/route53'
      autoload :S3, 'aws/api/service_translators/s3'
      autoload :SQS, 'aws/api/service_translators/sqs'
      autoload :SWF, 'aws/api/service_translators/swf'
    end

  end

  # @api private
  module Json
    autoload :Builder, 'aws/json/builder'
    autoload :ErrorParser, 'aws/json/error_parser'
    autoload :Parser, 'aws/json/parser'
    autoload :Serializer, 'aws/json/serializer'
  end

  module Plugins
    autoload :Credentials, 'aws/plugins/credentials'
    autoload :DynamoDBExtendedRetries, 'aws/plugins/dynamodb_extended_retries'
    autoload :GlacierApiVersion, 'aws/plugins/glacier_api_version'
    autoload :GlacierChecksums, 'aws/plugins/glacier_checksums'
    autoload :GlobalConfiguration, 'aws/plugins/global_configuration'
    autoload :JsonProtocol, 'aws/plugins/json_protocol'
    autoload :JsonRpcHeaders, 'aws/plugins/json_rpc_headers'
    autoload :QueryProtocol, 'aws/plugins/query_protocol'
    autoload :RegionalEndpoint, 'aws/plugins/regional_endpoint'
    autoload :RetryErrors, 'aws/plugins/retry_errors'
    autoload :S3BucketDns, 'aws/plugins/s3_bucket_dns'
    autoload :S3CompleteMultipartUploadFix, 'aws/plugins/s3_complete_multipart_upload_fix'
    autoload :S3GetBucketLocationFix, 'aws/plugins/s3_get_bucket_location_fix'
    autoload :S3Md5s, 'aws/plugins/s3_md5s'
    autoload :S3Redirects, 'aws/plugins/s3_redirects'
    autoload :S3Signer, 'aws/plugins/s3_signer'
    autoload :SignatureV2, 'aws/plugins/signature_v2'
    autoload :SignatureV3, 'aws/plugins/signature_v3'
    autoload :SignatureV4, 'aws/plugins/signature_v4'
    autoload :SQSQueueUrls, 'aws/plugins/sqs_queue_urls'
    autoload :SWFReadTimeouts, 'aws/plugins/swf_read_timeouts'
    autoload :UserAgent, 'aws/plugins/user_agent'
    autoload :XmlProtocol, 'aws/plugins/xml_protocol'
  end

  # @api private
  module Query
    autoload :Builder, 'aws/query/builder'
    autoload :Param, 'aws/query/param'
    autoload :ParamList, 'aws/query/param_list'
    autoload :Serializer, 'aws/query/serializer'
  end

  # @api private
  module Signers
    autoload :Base, 'aws/signers/base'
    autoload :Handler, 'aws/signers/handler'
    autoload :S3, 'aws/signers/s3'
    autoload :V2, 'aws/signers/v2'
    autoload :V3, 'aws/signers/v3'
    autoload :V4, 'aws/signers/v4'
  end

  # @api private
  module Xml
    autoload :Builder, 'aws/xml/builder'
    autoload :ErrorParser,  'aws/xml/error_parser'
    autoload :Parser, 'aws/xml/parser'
    autoload :Serializer, 'aws/xml/serializer'
  end

  class << self

    # @return [Hash] Returns a hash of default configuration options shared
    #   by all constructed clients.
    attr_accessor :config

    # Adds a plugin to every AWS client class.  This registers the plugin
    # with each versioned client for each service.
    # @param [Plugin] plugin
    # @return [void]
    def add_plugin(plugin)
      service_classes.values.each do |svc_class|
        svc_class.add_plugin(plugin)
      end
    end

    # Removes a plugin to from AWS client class.  This removes the plugin
    # from each versioned client for each service.
    # @param [Plugin] plugin
    # @return [void]
    def remove_plugin(plugin)
      service_classes.values.each do |svc_class|
        svc_class.remove_plugin(plugin)
      end
    end

    # @return [Array<Class>]
    # @api private
    def service_classes
      @service_classes ||= {}
    end

    # Registers a new service interface.  This method accepts a constant
    # (class name) for the new service class and a list of client API
    # versions.
    #
    #     Aws.add_servcie(:S3, ['apis/S3-2006-03-01.json'])
    #
    # This method is called for each service defined in the apis directory of
    # this project.
    #
    # @note You should normally not need to call this method directly.
    #
    # @param [Symbol] name The name of the new service class.
    # @param [Array<String, Seahorse::Model::Api>] apis
    # @return [Class<Service>]
    def add_service(name, apis = [])
      svc_class = const_set(name, Service.define(name.downcase.to_sym, apis))
      service_classes[svc_class.identifier] = svc_class
      self.class.send(:define_method, svc_class.identifier) do |options = {}|
        svc_class.new(options)
      end
      svc_class
    end

    private

    # @return Returns a hash of API paths grouped by their service class names.
    def bundled_apis
      Dir.glob(File.join(GEM_ROOT, 'apis', '*.json')).group_by do |path|
        File.basename(path).split('-').first
      end
    end

  end

  bundled_apis.each do |svc_class_name, api_versions|
    add_service(svc_class_name, api_versions)
  end

end
