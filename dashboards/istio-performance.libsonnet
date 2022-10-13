local g = (import 'utils.libsonnet');

{
  grafanaDashboards+:: {
    'istio-performance.json':
      g.dashboard('Istio Performance Dashboard', std.md5('20221013-istio-performance'))
        .addTemplate('cluster', 'istio_requests_total', 'cluster')
        .addRow(
            g.row('vCPU Usage')
                .addPanel(
                    g.timeseriesPanel('vCPU / 1k rps') +
                    g.queryPanel([
                        "(sum(irate(container_cpu_usage_seconds_total{cluster=\"$cluster\",pod=~\"istio-ingressgateway-.*\",container=\"istio-proxy\"}[1m])) / (round(sum(irate(istio_requests_total{cluster=\"$cluster\",source_workload=\"istio-ingressgateway\", reporter=\"source\"}[1m])), 0.001)/1000))",
                        "(sum(irate(container_cpu_usage_seconds_total{cluster=\"$cluster\",namespace!=\"istio-system\",container=\"istio-proxy\"}[1m]))/ (round(sum(irate(istio_requests_total{cluster=\"$cluster\"}[1m])), 0.001)/1000))/ (sum(irate(istio_requests_total{cluster=\"$cluster\",source_workload=\"istio-ingressgateway\"}[1m])) >bool 10)",
                    ],[
                        'istio-ingressgateway',
                        'istio-proxy',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'short',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 12,
                            x: 0,
                            y: 1,
                        },
                    }
                )

                .addPanel(
                    g.timeseriesPanel('vCPU') +
                    g.queryPanel([
                        "sum(rate(container_cpu_usage_seconds_total{cluster=\"$cluster\",pod=~\"istio-ingressgateway-.*\",container=\"istio-proxy\"}[1m]))",
                        "sum(rate(container_cpu_usage_seconds_total{cluster=\"$cluster\",namespace!=\"istio-system\",container=\"istio-proxy\"}[1m]))",
                    ],[
                        'istio-ingressgateway',
                        'istio-proxy',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'short',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 12,
                            x: 12,
                            y: 1,
                        },
                    }
                ) + {
                    gridPos: {
                        h: 1,
                        w: 24,
                        x: 0,
                        y: 0,
                    },
                }
        )

        .addRow(
            g.row('Memory and Data Rates')
                .addPanel(
                    g.timeseriesPanel('Memory Usage') +
                    g.queryPanel([
                        "sum(container_memory_working_set_bytes{cluster=\"$cluster\",pod=~\"istio-ingressgateway-.*\"}) / count(container_memory_working_set_bytes{cluster=\"$cluster\",pod=~\"istio-ingressgateway-.*\",container!=\"POD\"})",
                        "sum(container_memory_working_set_bytes{cluster=\"$cluster\",namespace!=\"istio-system\",container=\"istio-proxy\"}) / count(container_memory_working_set_bytes{cluster=\"$cluster\",namespace!=\"istio-system\",container=\"istio-proxy\"})",
                    ],[
                        'per istio-ingressgateway',
                        'per istio proxy',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'bytes',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 12,
                            x: 0,
                            y: 11,
                        },
                    }
                )            

                .addPanel(
                    g.timeseriesPanel('Bytes transferred / sec') +
                    g.queryPanel([
                        "sum(irate(istio_response_bytes_sum{cluster=\"$cluster\",source_workload=\"istio-ingressgateway\", reporter=\"source\"}[1m]))",
                        "sum(irate(istio_response_bytes_sum{cluster=\"$cluster\",source_workload_namespace!=\"istio-system\", reporter=\"source\"}[1m])) + sum(irate(istio_request_bytes_sum{cluster=\"$cluster\",source_workload_namespace!=\"istio-system\", reporter=\"source\"}[1m]))",
                    ],[
                        'istio-ingressgateway',
                        'istio-proxy',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'Bps',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 12,
                            x: 12,
                            y: 11,
                        },
                    }
                ) + {
                    gridPos: {
                        h: 1,
                        w: 24,
                        x: 0,
                        y: 10,
                    },
                }            

        )

        .addRow(
            g.row('Proxy Resource Usage')
                .addPanel(
                    g.timeseriesPanel('Memory') +
                    g.queryPanel([
                        "sum(container_memory_working_set_bytes{cluster=\"$cluster\",container=\"istio-proxy\"})",
                    ],[
                        'Total (k8s)',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'bytes',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 7,
                            w: 6,
                            x: 0,
                            y: 21,
                        },
                    }
                )            

                .addPanel(
                    g.timeseriesPanel('vCPU') +
                    g.queryPanel([
                        "sum(rate(container_cpu_usage_seconds_total{cluster=\"$cluster\",container=\"istio-proxy\"}[1m]))",
                    ],[
                        'Total (k8s)',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'short',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 7,
                            w: 6,
                            x: 6,
                            y: 21,
                        },
                    }
                )

                .addPanel(
                    g.timeseriesPanel('Disk') +
                    g.queryPanel([
                        "sum(container_fs_usage_bytes{cluster=\"$cluster\",container=\"istio-proxy\"})",
                    ],[
                        'Total (k8s)',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'bytes',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 7,
                            w: 6,
                            x: 12,
                            y: 21,
                        },
                    }
                )

                + {
                    gridPos: {
                        h: 1,
                        w: 24,
                        x: 0,
                        y: 20,
                    },
                }            

        )

        .addRow(
            g.row('Istiod Resource Usage')
                .addPanel(
                    g.timeseriesPanel('Memory') +
                    g.queryPanel([
                        "process_virtual_memory_bytes{cluster=\"$cluster\",job=\"istiod\"}",
                        "process_resident_memory_bytes{cluster=\"$cluster\",job=\"istiod\"}",
                        "go_memstats_heap_sys_bytes{cluster=\"$cluster\",job=\"istiod\"}",
                        "go_memstats_heap_alloc_bytes{cluster=\"$cluster\",job=\"istiod\"}",
                        "go_memstats_alloc_bytes{cluster=\"$cluster\",job=\"istiod\"}",
                        "go_memstats_heap_inuse_bytes{cluster=\"$cluster\",job=\"istiod\"}",
                        "go_memstats_stack_inuse_bytes{cluster=\"$cluster\",job=\"istiod\"}",
                        "sum(container_memory_working_set_bytes{cluster=\"$cluster\",container=~\"discovery|istio-proxy\", pod=~\"istiod-.*\"})",
                        "container_memory_working_set_bytes{cluster=\"$cluster\",container=~\"discovery|istio-proxy\", pod=~\"istiod-.*\"}",
                    ],[
                        'Virtual Memory',
                        'Resident Memory',
                        'heap sys',
                        'heap alloc',
                        'Alloc',
                        'Heap in-use',
                        'Stack in-use',
                        'Total (k8s)',
                        '{{ container }} (k8s)',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'bytes',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 7,
                            w: 6,
                            x: 0,
                            y: 30,
                        },
                    }
                )

                .addPanel(
                    g.timeseriesPanel('vCPU') +
                    g.queryPanel([
                        "sum(rate(container_cpu_usage_seconds_total{cluster=\"$cluster\",container=~\"discovery|istio-proxy\", pod=~\"istiod-.*\"}[1m]))",
                        "sum(rate(container_cpu_usage_seconds_total{cluster=\"$cluster\",container=~\"discovery|istio-proxy\", pod=~\"istiod-.*\"}[1m])) by (container)",
                        "irate(process_cpu_seconds_total{cluster=\"$cluster\",job=\"istiod\"}[1m])",
                    ],[
                        'Total (k8s)',
                        '{{ container }} (k8s)',
                        'pilot (self-reported)',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'short',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 7,
                            w: 6,
                            x: 6,
                            y: 30,
                        },
                    }
                )

                .addPanel(
                    g.timeseriesPanel('Disk') +
                    g.queryPanel([
                        "process_open_fds{cluster=\"$cluster\",job=\"istiod\"}",
                        "container_fs_usage_bytes{cluster=\"$cluster\",container=~\"discovery|istio-proxy\",pod=~\"istiod-.*\"}",
                    ],[
                        'Open FDs (pilot)',
                        '{{ container }}',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'bytes',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 7,
                            w: 6,
                            x: 12,
                            y: 30,
                        },
                    }
                )

                .addPanel(
                    g.timeseriesPanel('Goroutines') +
                    g.queryPanel([
                        "go_goroutines{cluster=\"$cluster\",job=\"istiod\"}",
                    ],[
                        'Number of Goroutines',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'short',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 7,
                            w: 6,
                            x: 18,
                            y: 30,
                        },
                    }
                )

                + {
                    gridPos: {
                        h: 1,
                        w: 24,
                        x: 0,
                        y: 29,
                    },
                }            
        )

  }
}
