local g = (import 'utils.libsonnet');

{
  grafanaDashboards+:: {
    'istio-mesh.json':
      g.dashboard('Istio Mesh Dashboard', std.md5('20221011-istio-mesh'))
        .addTemplate('cluster', 'istio_requests_total', 'cluster')

        .addRow(
            g.row()
                .addPanel(
                    g.statPanel('Global Request Volume', 'round(sum(irate(istio_requests_total{cluster="$cluster", reporter="source"}[1m])), 0.001)', 'reqps', false) + {
                        gridPos: {
                            h: 4,
                            w: 6,
                            x: 0,
                            y: 1,
                        },
                    }
                )
                .addPanel(
                    g.statPanel('Global Success Rate (non-5xx responses)', 'sum(rate(istio_requests_total{cluster="$cluster", reporter="source", response_code!~"5.*"}[1m])) / sum(rate(istio_requests_total{cluster="$cluster", reporter="source"}[1m]))', 'percentunit') + {
                        gridPos: {
                            h: 4,
                            w: 6,
                            x: 6,
                            y: 1,
                        },
                    }
                )
                .addPanel(
                    g.statPanel('4xxs', 'sum(irate(istio_requests_total{cluster="$cluster", reporter="source", response_code=~"4.*"}[1m]))', 'reqps', false) + {
                        gridPos: {
                            h: 4,
                            w: 6,
                            x: 12,
                            y: 1,
                        },
                    }
                )
                .addPanel(
                    g.statPanel('5xxs', 'sum(irate(istio_requests_total{cluster="$cluster", reporter="source", response_code=~"5.*"}[1m]))', 'reqps', false) + {
                        gridPos: {
                            h: 4,
                            w: 6,
                            x: 18,
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
            g.row()
                .addPanel(
                    g.statPanel('Virtual Services', 'max(pilot_k8s_cfg_events{cluster="$cluster", type="VirtualService", event="add"}) - (max(pilot_k8s_cfg_events{cluster="$cluster", type="VirtualService", event="delete"}) or max(up * 0))', 'short') + {
                        gridPos: {
                            h: 4,
                            w: 3,
                            x: 0,
                            y: 6,
                        },
                    }
                )
                .addPanel(
                    g.statPanel('Destination Rules', 'max(pilot_k8s_cfg_events{cluster="$cluster", type="DestinationRule", event="add"}) - (max(pilot_k8s_cfg_events{cluster="$cluster", type="DestinationRule", event="delete"}) or max(up * 0))', 'short') + {
                        gridPos: {
                            h: 4,
                            w: 3,
                            x: 3,
                            y: 6,
                        },
                    }
                )
                .addPanel(
                    g.statPanel('Gateways', 'max(pilot_k8s_cfg_events{cluster="$cluster", type="Gateway", event="add"}) - (max(pilot_k8s_cfg_events{cluster="$cluster", type="Gateway", event="delete"}) or max(up * 0))', 'short') + {
                        gridPos: {
                            h: 4,
                            w: 3,
                            x: 6,
                            y: 6,
                        },
                    }
                )
                .addPanel(
                    g.statPanel('Workload Entries', 'max(pilot_k8s_cfg_events{cluster="$cluster", type="WorkloadEntry", event="add"}) - (max(pilot_k8s_cfg_events{cluster="$cluster", type="WorkloadEntry", event="delete"}) or max(up * 0))', 'short') + {
                        gridPos: {
                            h: 4,
                            w: 3,
                            x: 9,
                            y: 6,
                        },
                    }
                )
                .addPanel(
                    g.statPanel('Service Entries', 'max(pilot_k8s_cfg_events{cluster="$cluster", type="ServiceEntry", event="add"}) - (max(pilot_k8s_cfg_events{cluster="$cluster", type="ServiceEntry", event="delete"}) or max(up * 0))', 'short') + {
                        gridPos: {
                            h: 4,
                            w: 3,
                            x: 12,
                            y: 6,
                        },
                    }
                )
                .addPanel(
                    g.statPanel('PeerAuthentication Policies', 'max(pilot_k8s_cfg_events{cluster="$cluster", type="PeerAuthentication", event="add"}) - (max(pilot_k8s_cfg_events{cluster="$cluster", type="PeerAuthentication", event="delete"}) or max(up * 0))', 'short') + {
                        gridPos: {
                            h: 4,
                            w: 3,
                            x: 15,
                            y: 6,
                        },
                    }
                )
                .addPanel(
                    g.statPanel('RequestAuthentication Policies', 'max(pilot_k8s_cfg_events{cluster="$cluster", type="RequestAuthentication", event="add"}) - (max(pilot_k8s_cfg_events{cluster="$cluster", type="RequestAuthentication", event="delete"}) or max(up * 0))', 'short')
                     + {
                        gridPos: {
                            h: 4,
                            w: 3,
                            x: 18,
                            y: 6,
                        },
                    }
                )
                .addPanel(
                    g.statPanel('Authorization Policies', 'max(pilot_k8s_cfg_events{cluster="$cluster", type="AuthorizationPolicy", event="add"}) - (max(pilot_k8s_cfg_events{cluster="$cluster", type="AuthorizationPolicy", event="delete"}) or max(up * 0))', 'short') + {
                        gridPos: {
                            h: 4,
                            w: 3,
                            x: 21,
                            y: 6,
                        },
                    }
                ) + {
                    gridPos: {
                        h: 1,
                        w: 24,
                        x: 0,
                        y: 5,
                    },
                }

        )

        .addRow(
            g.row()
                .addPanel(
                    {
                        title: 'HTTP/GRPC Workloads',
                        gridPos: {
                            h: 18,
                            w: 24,
                            x: 0,
                            y: 11,
                        },
                    } +
                    g.tablePanel([
                        "label_join(sum(rate(istio_requests_total{cluster=\"$cluster\", reporter=\"source\", response_code=\"200\"}[1m])) by (destination_workload, destination_workload_namespace, destination_service), \"destination_workload_var\", \".\", \"destination_workload\", \"destination_workload_namespace\")",
                        "label_join((histogram_quantile(0.50, sum(rate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\", reporter=\"source\"}[1m])) by (le, destination_workload, destination_workload_namespace)) / 1000) or histogram_quantile(0.50, sum(rate(istio_request_duration_seconds_bucket{cluster=\"$cluster\", reporter=\"source\"}[1m])) by (le, destination_workload, destination_workload_namespace)), \"destination_workload_var\", \".\", \"destination_workload\", \"destination_workload_namespace\")",
                        "label_join((histogram_quantile(0.90, sum(rate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\", reporter=\"source\"}[1m])) by (le, destination_workload, destination_workload_namespace)) / 1000) or histogram_quantile(0.90, sum(rate(istio_request_duration_seconds_bucket{cluster=\"$cluster\", reporter=\"source\"}[1m])) by (le, destination_workload, destination_workload_namespace)), \"destination_workload_var\", \".\", \"destination_workload\", \"destination_workload_namespace\")",
                        "label_join((histogram_quantile(0.99, sum(rate(istio_request_duration_milliseconds_bucket{cluster=\"$cluster\", reporter=\"source\"}[1m])) by (le, destination_workload, destination_workload_namespace)) / 1000) or histogram_quantile(0.99, sum(rate(istio_request_duration_seconds_bucket{cluster=\"$cluster\", reporter=\"source\"}[1m])) by (le, destination_workload, destination_workload_namespace)), \"destination_workload_var\", \".\", \"destination_workload\", \"destination_workload_namespace\")",
                        "label_join((sum(rate(istio_requests_total{cluster=\"$cluster\", reporter=\"source\", response_code!~\"5.*\"}[1m])) by (destination_workload, destination_workload_namespace) / sum(rate(istio_requests_total{cluster=\"$cluster\", reporter=\"source\"}[1m])) by (destination_workload, destination_workload_namespace)), \"destination_workload_var\", \".\", \"destination_workload\", \"destination_workload_namespace\")",
                    ], {
                        destination_workload: {alias: '', type: 'hidden'},
                        'Value #A': {alias: 'Requests', type: 'number', unit: 'ops'},
                        'Value #B': {alias: 'P50 Latency', type: 'number', unit: 's'},
                        'Value #C': {alias: 'P90 Latency', type: 'number', unit: 's'},
                        'Value #D': {alias: 'P99 Latency', type: 'number', unit: 's'},
                        'Value #E': {alias: 'Success Rate', type: 'number', unit: 'percentunit'},
                        destination_workload_var: {alias: 'Workload', type: 'number', unit: 'short'},
                        destination_service: {alias: 'Service', type: 'string'},
                        destination_workload_namespace: {alias: '', type: 'hidden'},
                    })
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
            g.row()
                .addPanel(
                    {
                        title: 'TCP Workloads',
                        gridPos: {
                            h: 18,
                            w: 24,
                            x: 0,
                            y: 31,
                        },
                    } +
                    g.tablePanel([
                        "label_join(sum(rate(istio_tcp_received_bytes_total{cluster=\"$cluster\", reporter=\"source\"}[1m])) by (destination_workload, destination_workload_namespace, destination_service), \"destination_workload_var\", \".\", \"destination_workload\", \"destination_workload_namespace\")",
                        "label_join(sum(rate(istio_tcp_sent_bytes_total{cluster=\"$cluster\", reporter=\"source\"}[1m])) by (destination_workload, destination_workload_namespace, destination_service), \"destination_workload_var\", \".\", \"destination_workload\", \"destination_workload_namespace\")",
                    ], {
                        destination_workload: {alias: '', type: "hidden"},
                        'Value #A': {alias: 'Bytes Sent', unit: "Bps"},
                        'Value #B': {alias: 'Bytes Received', unit: "Bps"},
                        'Value #C': {alias: 'P90 Latency'},
                        'Value #D': {alias: 'P99 Latency'},
                        'Value #E': {alias: 'Success Rate'},
                        destination_workload_var: {alias: 'Workload', type: 'string'},
                        destination_workload_namespace: {alias: '', type: 'hidden'},
                        destination_service: {alias: 'Service', type: 'number'},
                    })
                ) + {
                    gridPos: {
                        h: 1,
                        w: 24,
                        x: 0,
                        y: 30,
                    },
                }
        )

        .addRow(
            g.row()
                .addPanel(
                    {
                        title: 'Istio Component Versions',
                        gridPos: {
                            h: 9,
                            w: 24,
                            x: 0,
                            y: 51,
                        },
                    } +
                    g.tablePanel([
                        "sum(istio_build{cluster=\"$cluster\"}) by (component, tag)"
                    ], {
                        'Value': {alias: '', type: 'hidden'},
                    })
                ) + {
                    gridPos: {
                        h: 1,
                        w: 24,
                        x: 0,
                        y: 50,
                    },
                }
        )

  }
}
