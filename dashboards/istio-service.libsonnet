local g = (import 'utils.libsonnet');

{
  grafanaDashboards+:: {
    'istio-service.json':
      g.dashboard('Istio Service Dashboard', std.md5('20221109-istio-service'))
        .addTemplate('cluster', 'istio_requests_total', 'cluster')
        .addQueryTemplate('service', 'sum(istio_requests_total{cluster="$cluster"}) by (destination_service)', '/.*destination_service="([^"]*).*/')
        #.addTemplate('service', null, 'destination_service')
        .addTemplate('reporter', null, 'reporter')
        .addQueryTemplate('client_cluster', "sum(istio_requests_total{reporter=~\"$reporter\", destination_service=\"$service\"}) by (source_cluster) or sum(istio_tcp_sent_bytes_total{reporter=~\"$reporter\", destination_service=~\"$service\"}) by (source_cluster)", "/.*cluster=\"([^\"]*).*/", true, true, true)
        .addQueryTemplate('client_namespace', "sum(istio_requests_total{reporter=~\"$reporter\", destination_service=\"$service\"}) by (source_workload_namespace) or sum(istio_tcp_sent_bytes_total{reporter=~\"$reporter\", destination_service=~\"$service\"}) by (source_workload_namespace)", "/.*namespace=\"([^\"]*).*/", true, true, true)
        .addQueryTemplate('client_workload', "sum(istio_requests_total{reporter=~\"$reporter\", destination_service=~\"$service\", source_workload_namespace=~\"$client_namespace\"}) by (source_workload) or sum(istio_tcp_sent_bytes_total{reporter=~\"$reporter\", destination_service=~\"$service\", source_workload_namespace=~\"$client_namespace\"}) by (source_workload)", "/.*workload=\"([^\"]*).*/", true, true, true)
        .addQueryTemplate('service_cluster', "sum(istio_requests_total{reporter=\"destination\", destination_service=\"$service\"}) by (destination_cluster) or sum(istio_tcp_sent_bytes_total{reporter=\"destination\", destination_service=~\"$service\"}) by (destination_cluster)", "/.*cluster=\"([^\"]*).*/", true, true, true)
        .addQueryTemplate('service_namespace', "sum(istio_requests_total{reporter=\"destination\", destination_service=\"$service\"}) by (destination_workload_namespace) or sum(istio_tcp_sent_bytes_total{reporter=\"destination\", destination_service=~\"$service\"}) by (destination_workload_namespace)", "/.*namespace=\"([^\"]*).*/", true, true, true)
        .addQueryTemplate('service_workload', "sum(istio_requests_total{reporter=\"destination\", destination_service=~\"$service\", destination_cluster=~\"$service_cluster\", destination_workload_namespace=~\"$service_namespace\"}) by (destination_workload) or sum(istio_tcp_sent_bytes_total{reporter=\"destination\", destination_service=~\"$service\", destination_cluster=~\"$service_cluster\", destination_workload_namespace=~\"$service_namespace\"}) by (destination_workload)", "/.*workload=\"([^\"]*).*/", true, true, true)

        .addRow(
            g.row('General')
                .addPanel(
                    g.statPanel('Client Request Volume', "round(sum(irate(istio_requests_total{cluster=\"$cluster\",reporter=~\"$reporter\",destination_service=~\"$service\"}[5m])), 0.001)", 'reqps', false) + {
                        gridPos: {
                            h: 4,
                            w: 6,
                            x: 0,
                            y: 1,
                        },
                    }
                )
                .addPanel(
                    g.statPanel('Client Success Rate (non-5xx responses)', "sum(irate(istio_requests_total{cluster=\"$cluster\",reporter=~\"$reporter\",destination_service=~\"$service\",response_code!~\"5.*\"}[5m])) / sum(irate(istio_requests_total{cluster=\"$cluster\",reporter=~\"$reporter\",destination_service=~\"$service\"}[5m]))", 'percentunit', false) + {
                        gridPos: {
                            h: 4,
                            w: 6,
                            x: 6,
                            y: 1,
                        },
                    }
                )
                /*
                .addPanel(
                    g.statPanel('TCP Received Bytes', "sum(irate(istio_tcp_received_bytes_total{cluster=\"$cluster\",reporter=~\"$reporter\", destination_service=~\"$service\"}[1m]))", 'reqps', false) + {
                        gridPos: {
                            h: 4,
                            w: 6,
                            x: 12,
                            y: 1,
                        },
                    }
                )
                */
                .addPanel(
                    g.statPanel('Server Request Volume', "round(sum(irate(istio_requests_total{cluster=\"$cluster\",reporter=\"destination\",destination_service=~\"$service\"}[5m])), 0.001)", 'reqps', false) + {
                        gridPos: {
                            h: 4,
                            w: 6,
                            x: 12,
                            y: 1,
                        },
                    }
                )
                .addPanel(
                    g.statPanel('Server Success Rate (non-5xx responses)', "sum(irate(istio_requests_total{cluster=\"$cluster\",reporter=\"destination\",destination_service=~\"$service\",response_code!~\"5.*\"}[5m])) / sum(irate(istio_requests_total{cluster=\"$cluster\",reporter=\"destination\",destination_service=~\"$service\"}[5m]))", 'percentunit', false) + {
                        gridPos: {
                            h: 4,
                            w: 6,
                            x: 18,
                            y: 1,
                        },
                    }
                )
                .addPanel(
                    g.timeseriesPanel('Client Request Duration') +
                    g.queryPanel([
                        "(histogram_quantile(0.50, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\",destination_service=~\"$service\"}[1m])) by (le)) / 1000) or histogram_quantile(0.50, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\",destination_service=~\"$service\"}[1m])) by (le))",
                        "(histogram_quantile(0.90, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\",destination_service=~\"$service\"}[1m])) by (le)) / 1000) or histogram_quantile(0.90, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\",destination_service=~\"$service\"}[1m])) by (le))",
                        "(histogram_quantile(0.99, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\",destination_service=~\"$service\"}[1m])) by (le)) / 1000) or histogram_quantile(0.99, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\",destination_service=~\"$service\"}[1m])) by (le))",
                    ],[
                        'P50',
                        'P90',
                        'P99',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 's',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 12,
                            x: 0,
                            y: 6,
                        },
                    }
                )
                .addPanel(
                    g.timeseriesPanel('Server Request Duration') +
                    g.queryPanel([
                        "(histogram_quantile(0.50, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=\"destination\",destination_service=~\"$service\"}[1m])) by (le)) / 1000) or histogram_quantile(0.50, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=\"destination\",destination_service=~\"$service\"}[1m])) by (le))",
                        "(histogram_quantile(0.90, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=\"destination\",destination_service=~\"$service\"}[1m])) by (le)) / 1000) or histogram_quantile(0.90, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=\"destination\",destination_service=~\"$service\"}[1m])) by (le))",
                        "(histogram_quantile(0.99, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=\"destination\",destination_service=~\"$service\"}[1m])) by (le)) / 1000) or histogram_quantile(0.99, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=\"destination\",destination_service=~\"$service\"}[1m])) by (le))",
                    ],[
                        'P50',
                        'P90',
                        'P99',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 's',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 12,
                            x: 12,
                            y: 6,
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
            g.row('Client Workloads')
                .addPanel(
                    g.timeseriesPanel('Incoming Requests By Source And Response Code') +
                    g.queryPanel([
                        "round(sum(irate(istio_requests_total{cluster=\"$cluster\",connection_security_policy=\"mutual_tls\",destination_service=~\"$service\",reporter=~\"$reporter\",source_workload=~\"$client_workload\",source_workload_namespace=~\"$client_namespace\"}[5m])) by (source_workload, source_workload_namespace, response_code), 0.001)",
                        "round(sum(irate(istio_requests_total{cluster=\"$cluster\",connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", reporter=~\"$reporter\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[5m])) by (source_workload, source_workload_namespace, response_code), 0.001)",
                    ],[
                        '{{ source_workload }}.{{ source_workload_namespace }} : {{ response_code }} (🔐mTLS)',
                        '{{ source_workload }}.{{ source_workload_namespace }} : {{ response_code }}',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'reqps',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 12,
                            x: 0,
                            y: 15,
                        },
                    }
                )
                .addPanel(
                    g.timeseriesPanel('Incoming Success Rate (non-5xx responses) By Source') +
                    g.queryPanel([
                        "sum(irate(istio_requests_total{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\",response_code!~\"5.*\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[5m])) by (source_workload, source_workload_namespace) / sum(irate(istio_requests_total{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[5m])) by (source_workload, source_workload_namespace)",
                        "sum(irate(istio_requests_total{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\",response_code!~\"5.*\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[5m])) by (source_workload, source_workload_namespace) / sum(irate(istio_requests_total{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[5m])) by (source_workload, source_workload_namespace)",
                    ],[
                        '{{ source_workload }}.{{ source_workload_namespace }} (🔐mTLS)',
                        '{{ source_workload }}.{{ source_workload_namespace }}',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'percentunit',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 12,
                            x: 12,
                            y: 15,
                        },
                    }
                )
                .addPanel(
                    g.timeseriesPanel('Incoming Request Duration By Source') +
                    g.queryPanel([
                        "(histogram_quantile(0.50, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le)) / 1000) or histogram_quantile(0.50, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "(histogram_quantile(0.90, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le)) / 1000) or histogram_quantile(0.90, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "(histogram_quantile(0.95, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le)) / 1000) or histogram_quantile(0.95, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "(histogram_quantile(0.99, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le)) / 1000) or histogram_quantile(0.99, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "(histogram_quantile(0.50, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le)) / 1000) or histogram_quantile(0.50, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "(histogram_quantile(0.90, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le)) / 1000) or histogram_quantile(0.90, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "(histogram_quantile(0.95, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le)) / 1000) or histogram_quantile(0.95, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "(histogram_quantile(0.99, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le)) / 1000) or histogram_quantile(0.99, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                    ],[
                        '{{source_workload}}.{{source_workload_namespace}} P50 (🔐mTLS)',
                        '{{source_workload}}.{{source_workload_namespace}} P90 (🔐mTLS)',
                        '{{source_workload}}.{{source_workload_namespace}} P95 (🔐mTLS)',
                        '{{source_workload}}.{{source_workload_namespace}} P99 (🔐mTLS)',
                        '{{source_workload}}.{{source_workload_namespace}} P50',
                        '{{source_workload}}.{{source_workload_namespace}} P90',
                        '{{source_workload}}.{{source_workload_namespace}} P95',
                        '{{source_workload}}.{{source_workload_namespace}} P99',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 's',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 8,
                            x: 0,
                            y: 23,
                        },
                    }
                )
                .addPanel(
                    g.timeseriesPanel('Incoming Request Size By Source') +
                    g.queryPanel([
                        "histogram_quantile(0.50, sum(irate(istio_request_bytes_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "histogram_quantile(0.90, sum(irate(istio_request_bytes_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "histogram_quantile(0.95, sum(irate(istio_request_bytes_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "histogram_quantile(0.99, sum(irate(istio_request_bytes_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "histogram_quantile(0.50, sum(irate(istio_request_bytes_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "histogram_quantile(0.90, sum(irate(istio_request_bytes_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "histogram_quantile(0.95, sum(irate(istio_request_bytes_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "histogram_quantile(0.99, sum(irate(istio_request_bytes_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                    ],[
                        '{{source_workload}}.{{source_workload_namespace}} P50 (🔐mTLS)',
                        '{{source_workload}}.{{source_workload_namespace}} P90 (🔐mTLS)',
                        '{{source_workload}}.{{source_workload_namespace}} P95 (🔐mTLS)',
                        '{{source_workload}}.{{source_workload_namespace}} P99 (🔐mTLS)',
                        '{{source_workload}}.{{source_workload_namespace}} P50',
                        '{{source_workload}}.{{source_workload_namespace}} P90',
                        '{{source_workload}}.{{source_workload_namespace}} P95',
                        '{{source_workload}}.{{source_workload_namespace}} P99',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'bytes',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 8,
                            x: 8,
                            y: 23,
                        },
                    }
                )
                .addPanel(
                    g.timeseriesPanel('Response Size By Source') +
                    g.queryPanel([
                        "histogram_quantile(0.50, sum(irate(istio_response_bytes_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "histogram_quantile(0.90, sum(irate(istio_response_bytes_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "histogram_quantile(0.95, sum(irate(istio_response_bytes_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "histogram_quantile(0.99, sum(irate(istio_response_bytes_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "histogram_quantile(0.50, sum(irate(istio_response_bytes_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "histogram_quantile(0.90, sum(irate(istio_response_bytes_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "histogram_quantile(0.95, sum(irate(istio_response_bytes_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                        "histogram_quantile(0.99, sum(irate(istio_response_bytes_bucket{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace, le))",
                    ],[
                        '{{source_workload}}.{{source_workload_namespace}} P50 (🔐mTLS)',
                        '{{source_workload}}.{{source_workload_namespace}} P90 (🔐mTLS)',
                        '{{source_workload}}.{{source_workload_namespace}} P95 (🔐mTLS)',
                        '{{source_workload}}.{{source_workload_namespace}} P99 (🔐mTLS)',
                        '{{source_workload}}.{{source_workload_namespace}} P50',
                        '{{source_workload}}.{{source_workload_namespace}} P90',
                        '{{source_workload}}.{{source_workload_namespace}} P95',
                        '{{source_workload}}.{{source_workload_namespace}} P99',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'bytes',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 8,
                            x: 16,
                            y: 23,
                        },
                    }
                )
                .addPanel(
                    g.timeseriesPanel('Bytes Received from Incoming TCP Connection') +
                    g.queryPanel([
                        "round(sum(irate(istio_tcp_received_bytes_total{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace), 0.001)",
                        "round(sum(irate(istio_tcp_received_bytes_total{cluster=\"$cluster\",reporter=~\"$reporter\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace), 0.001)",
                    ],[
                        '{{source_workload}}.{{source_workload_namespace}} (🔐mTLS)',
                        '{{source_workload}}.{{source_workload_namespace}}',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'bps',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 12,
                            x: 0,
                            y: 31,
                        },
                    }
                )
                .addPanel(
                    g.timeseriesPanel('Bytes Sent to Incoming TCP Connection') +
                    g.queryPanel([
                        "round(sum(irate(istio_tcp_sent_bytes_total{cluster=\"$cluster\",connection_security_policy=\"mutual_tls\", reporter=~\"$reporter\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace), 0.001)",
                        "round(sum(irate(istio_tcp_sent_bytes_total{cluster=\"$cluster\",connection_security_policy!=\"mutual_tls\", reporter=~\"$reporter\", destination_service=~\"$service\", source_workload=~\"$client_workload\", source_workload_namespace=~\"$client_namespace\"}[1m])) by (source_workload, source_workload_namespace), 0.001)",
                    ],[
                        '{{source_workload}}.{{source_workload_namespace}} (🔐mTLS)',
                        '{{source_workload}}.{{source_workload_namespace}}',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'bps',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 12,
                            x: 12,
                            y: 31,
                        },
                    }
                )
                +
                {
                    gridPos: {
                        h: 1,
                        w: 24,
                        x: 0,
                        y: 13,
                    },
                }
        )
        .addRow(
            g.row('Service Workloads')
                .addPanel(
                    g.timeseriesPanel('Incoming Requests By Destination Workload And Response Code') +
                    g.queryPanel([
                        "round(sum(irate(istio_requests_total{cluster=\"$cluster\",connection_security_policy=\"mutual_tls\",destination_service=~\"$service\",reporter=\"destination\",destination_workload=~\"$service_workload\",destination_workload_namespace=~\"$service_namespace\"}[5m])) by (destination_workload, destination_workload_namespace, response_code), 0.001)",
                        "round(sum(irate(istio_requests_total{cluster=\"$cluster\",connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", reporter=\"destination\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[5m])) by (destination_workload, destination_workload_namespace, response_code), 0.001)",
                    ],[
                        '{{ destination_workload }}.{{ destination_workload_namespace }} : {{ response_code }} (🔐mTLS)',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} : {{ response_code }}',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'reqps',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 12,
                            x: 0,
                            y: 39,
                        },
                    }
                )
                .addPanel(
                    g.timeseriesPanel('Incoming Success Rate (non-5xx responses) By Destination Workload') +
                    g.queryPanel([
                        "sum(irate(istio_requests_total{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\",response_code!~\"5.*\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[5m])) by (destination_workload, destination_workload_namespace) / sum(irate(istio_requests_total{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[5m])) by (destination_workload, destination_workload_namespace)",
                        "sum(irate(istio_requests_total{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\",response_code!~\"5.*\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[5m])) by (destination_workload, destination_workload_namespace) / sum(irate(istio_requests_total{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[5m])) by (destination_workload, destination_workload_namespace)",
                    ],[
                        '{{ destination_workload }}.{{ destination_workload_namespace }} (🔐mTLS)',
                        '{{ destination_workload }}.{{ destination_workload_namespace }}',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'percentunit',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 12,
                            x: 12,
                            y: 39,
                        },
                    }
                )
                .addPanel(
                    g.timeseriesPanel('Incoming Request Duration By Service Workload') +
                    g.queryPanel([
                        "(histogram_quantile(0.50, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le)) / 1000) or histogram_quantile(0.50, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "(histogram_quantile(0.90, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le)) / 1000) or histogram_quantile(0.90, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "(histogram_quantile(0.95, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le)) / 1000) or histogram_quantile(0.95, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "(histogram_quantile(0.99, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le)) / 1000) or histogram_quantile(0.99, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "(histogram_quantile(0.50, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le)) / 1000) or histogram_quantile(0.50, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "(histogram_quantile(0.90, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le)) / 1000) or histogram_quantile(0.90, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "(histogram_quantile(0.95, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le)) / 1000) or histogram_quantile(0.95, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "(histogram_quantile(0.99, sum(irate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le)) / 1000) or histogram_quantile(0.99, sum(irate(istio_request_duration_seconds_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                    ],[
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P50 (🔐mTLS)',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P90 (🔐mTLS)',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P95 (🔐mTLS)',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P99 (🔐mTLS)',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P50',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P90',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P95',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P99',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 's',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 8,
                            x: 0,
                            y: 47,
                        },
                    }
                )
                .addPanel(
                    g.timeseriesPanel('Incoming Request Size By Service Workload') +
                    g.queryPanel([
                        "histogram_quantile(0.50, sum(irate(istio_request_bytes_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "histogram_quantile(0.90, sum(irate(istio_request_bytes_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "histogram_quantile(0.95, sum(irate(istio_request_bytes_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "histogram_quantile(0.99, sum(irate(istio_request_bytes_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "histogram_quantile(0.50, sum(irate(istio_request_bytes_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "histogram_quantile(0.90, sum(irate(istio_request_bytes_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "histogram_quantile(0.95, sum(irate(istio_request_bytes_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "histogram_quantile(0.99, sum(irate(istio_request_bytes_bucket{cluster=\"$cluster\",reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                    ],[
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P50 (🔐mTLS)',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P90 (🔐mTLS)',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P95 (🔐mTLS)',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P99 (🔐mTLS)',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P50',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P90',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P95',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P99',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'bytes',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 8,
                            x: 8,
                            y: 47,
                        },
                    }
                )
                .addPanel(
                    g.timeseriesPanel('Response Size By Service Workload') +
                    g.queryPanel([
                        "histogram_quantile(0.50, sum(irate(istio_response_bytes_bucket{cluster=\"$cluster\", reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "histogram_quantile(0.90, sum(irate(istio_response_bytes_bucket{cluster=\"$cluster\", reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "histogram_quantile(0.95, sum(irate(istio_response_bytes_bucket{cluster=\"$cluster\", reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "histogram_quantile(0.99, sum(irate(istio_response_bytes_bucket{cluster=\"$cluster\", reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "histogram_quantile(0.50, sum(irate(istio_response_bytes_bucket{cluster=\"$cluster\", reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "histogram_quantile(0.90, sum(irate(istio_response_bytes_bucket{cluster=\"$cluster\", reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "histogram_quantile(0.95, sum(irate(istio_response_bytes_bucket{cluster=\"$cluster\", reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                        "histogram_quantile(0.99, sum(irate(istio_response_bytes_bucket{cluster=\"$cluster\", reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace, le))",
                    ],[
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P50 (🔐mTLS)',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P90 (🔐mTLS)',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P95 (🔐mTLS)',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P99 (🔐mTLS)',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P50',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P90',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P95',
                        '{{ destination_workload }}.{{ destination_workload_namespace }} P99',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'bytes',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 8,
                            x: 16,
                            y: 47,
                        },
                    }
                )
                .addPanel(
                    g.timeseriesPanel('Bytes Received from Incoming TCP Connection') +
                    g.queryPanel([
                        "round(sum(irate(istio_tcp_received_bytes_total{cluster=\"$cluster\", reporter=\"destination\", connection_security_policy=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace), 0.001)",
                        "round(sum(irate(istio_tcp_received_bytes_total{cluster=\"$cluster\", reporter=\"destination\", connection_security_policy!=\"mutual_tls\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace), 0.001)",
                    ],[
                        '{{ destination_workload }}.{{ destination_workload_namespace}} (🔐mTLS)',
                        '{{ destination_workload }}.{{ destination_workload_namespace}}',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'bps',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 12,
                            x: 0,
                            y: 55,
                        },
                    }
                )
                .addPanel(
                    g.timeseriesPanel('Bytes Sent to Incoming TCP Connection') +
                    g.queryPanel([
                        "round(sum(irate(istio_tcp_sent_bytes_total{cluster=\"$cluster\", connection_security_policy=\"mutual_tls\", reporter=\"destination\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace), 0.001)",
                        "round(sum(irate(istio_tcp_sent_bytes_total{cluster=\"$cluster\", connection_security_policy!=\"mutual_tls\", reporter=\"destination\", destination_service=~\"$service\", destination_workload=~\"$service_workload\", destination_workload_namespace=~\"$service_namespace\"}[1m])) by (destination_workload, destination_workload_namespace), 0.001)",
                    ],[
                        '{{ destination_workload }}.{{destination_workload_namespace }} (🔐mTLS)',
                        '{{ destination_workload }}.{{destination_workload_namespace }}',
                    ]) + {
                        fieldConfig: {
                            defaults: {
                                unit: 'bps',
                            },
                            overrides: [],
                        },
                        gridPos: {
                            h: 8,
                            w: 12,
                            x: 12,
                            y: 55,
                        },
                    }
                )
                +
                {
                    gridPos: {
                        h: 1,
                        w: 24,
                        x: 0,
                        y: 38,
                    },
                }
        )
  }
}
