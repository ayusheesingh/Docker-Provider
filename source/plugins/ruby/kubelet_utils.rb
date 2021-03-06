# Copyright (c) Microsoft Corporation.  All rights reserved.
#!/usr/local/bin/ruby
# frozen_string_literal: true

require "logger"
require "yajl/json_gem"
require_relative "CAdvisorMetricsAPIClient"
require_relative "KubernetesApiClient"

class KubeletUtils
  @log_path = "/var/opt/microsoft/docker-cimprov/log/filter_cadvisor2mdm.log"
  @log = Logger.new(@log_path, 1, 5000000)

  class << self
    def get_node_capacity
      begin
        cpu_capacity = 1.0
        memory_capacity = 1.0

        response = CAdvisorMetricsAPIClient.getNodeCapacityFromCAdvisor(winNode: nil)
        if !response.nil? && !response.body.nil?
          cpu_capacity = JSON.parse(response.body)["num_cores"].nil? ? 1.0 : (JSON.parse(response.body)["num_cores"] * 1000.0)
          memory_capacity = JSON.parse(response.body)["memory_capacity"].nil? ? 1.0 : JSON.parse(response.body)["memory_capacity"].to_f
          @log.info "CPU = #{cpu_capacity}mc Memory = #{memory_capacity / 1024 / 1024}MB"
          return [cpu_capacity, memory_capacity]
        end
      rescue => errorStr
        @log.info "Error get_node_capacity: #{errorStr}"
        ApplicationInsightsUtility.sendExceptionTelemetry(errorStr)
      end
    end

    def get_all_container_limits
      begin
        @log.info "in get_all_container_limits..."
        clusterId = KubernetesApiClient.getClusterId
        containerCpuLimitHash = {}
        containerMemoryLimitHash = {}
        containerResourceDimensionHash = {}
        response = CAdvisorMetricsAPIClient.getPodsFromCAdvisor(winNode: nil)
        if !response.nil? && !response.body.nil? && !response.body.empty?
          podInventory = Yajl::Parser.parse(StringIO.new(response.body))
          podInventory["items"].each do |items|
            @log.info "in pod inventory items..."
            podNameSpace = items["metadata"]["namespace"]
            podName = items["metadata"]["name"]
            podUid = KubernetesApiClient.getPodUid(podNameSpace, items["metadata"])
            @log.info "podUid: #{podUid}"
            if podUid.nil?
              next
            end

            # Setting default to No Controller in case it is null or empty
            controllerName = "No Controller"

            if !items["metadata"]["ownerReferences"].nil? &&
               !items["metadata"]["ownerReferences"][0].nil? &&
               !items["metadata"]["ownerReferences"][0]["name"].nil? &&
               !items["metadata"]["ownerReferences"][0]["name"].empty?
              controllerName = items["metadata"]["ownerReferences"][0]["name"]
            end

            podContainers = []
            # @log.info "items[spec][containers]: #{items["spec"]["containers"]}"
            if items["spec"].key?("containers") && !items["spec"]["containers"].empty?
              podContainers = podContainers + items["spec"]["containers"]
            end
            # Adding init containers to the record list as well.
            if items["spec"].key?("initContainers") && !items["spec"]["initContainers"].empty?
              podContainers = podContainers + items["spec"]["initContainers"]
            end

            if !podContainers.empty?
              podContainers.each do |container|
                @log.info "in podcontainers for loop..."
                # containerName = "No name"
                containerName = container["name"]
                key = clusterId + "/" + podUid + "/" + containerName
                containerResourceDimensionHash[key] = [containerName, podName, controllerName, podNameSpace].join("~~")
                if !container["resources"].nil? && !container["resources"]["limits"].nil? && !containerName.nil?
                  cpuLimit = container["resources"]["limits"]["cpu"]
                  memoryLimit = container["resources"]["limits"]["memory"]
                  @log.info "cpuLimit: #{cpuLimit}"
                  @log.info "memoryLimit: #{memoryLimit}"
                  # Get cpu limit in nanocores
                  containerCpuLimitHash[key] = !cpuLimit.nil? ? KubernetesApiClient.getMetricNumericValue("cpu", cpuLimit) : 0
                  # Get memory limit in bytes
                  containerMemoryLimitHash[key] = !memoryLimit.nil? ? KubernetesApiClient.getMetricNumericValue("memory", memoryLimit) : 0
                end
              end
            end
          end
        end
      rescue => errorStr
        @log.info "Error in get_all_container_limits: #{errorStr}"
        ApplicationInsightsUtility.sendExceptionTelemetry(errorStr)
      end
      @log.info "containerCpuLimitHash: #{containerCpuLimitHash}"
      @log.info "containerMemoryLimitHash: #{containerMemoryLimitHash}"
      @log.info "containerResourceDimensionHash: #{containerResourceDimensionHash}"

      return [containerCpuLimitHash, containerMemoryLimitHash, containerResourceDimensionHash]
    end
  end
end
