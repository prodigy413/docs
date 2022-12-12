~~~
      - rule {
          - name     = "test-rule-01" -> null
          - priority = 0 -> null

          - action {

              - count {
                }
            }

          - statement {
              - and_statement {
                  - statement {

                      - not_statement {
                          - statement {

                              - label_match_statement {
                                  - key   = "awswaf:managed:aws:bot-control:signal:non_browser_user_agent" -> null
                                  - scope = "LABEL" -> null
                                }
                            }
                        }
                    }
                  - statement {

                      - not_statement {
                          - statement {

                              - byte_match_statement {
                                  - positional_constraint = "EXACTLY" -> null
                                  - search_string         = "SAP-CIAM" -> null

                                  - field_to_match {

                                      - single_header {
                                          - name = "user-agent" -> null
                                        }
                                    }

                                  - text_transformation {
                                      - priority = 0 -> null
                                      - type     = "NONE" -> null
                                    }
                                }
                            }
                        }
                    }
                }
            }

          - visibility_config {
              - cloudwatch_metrics_enabled = true -> null
              - metric_name                = "test-rule-01" -> null
              - sampled_requests_enabled   = true -> null
            }
        }





























      - rule {
          - name     = "test-rule-01" -> null
          - priority = 0 -> null

          - action {

              - count {
                }
            }

          - statement {
              - and_statement {
                  - statement {

                      - not_statement {
                          - statement {

                              - label_match_statement {
                                  - key   = "awswaf:managed:aws:bot-control:signal:non_browser_user_agent" -> null
                                  - scope = "LABEL" -> null
                                }
                            }
                        }
                    }
                  - statement {

                      - not_statement {
                          - statement {

                              - regex_pattern_set_reference_statement {
                                  - arn = "arn:aws:wafv2:us-east-1:844065555252:global/regexpatternset/test/dbccc997-9127-4af8-9e64-ceab9acdc1ed" -> null

                                  - field_to_match {

                                      - single_header {
                                          - name = "user-agent" -> null
                                        }
                                    }

                                  - text_transformation {
                                      - priority = 0 -> null
                                      - type     = "NONE" -> null
                                    }
                                }
                            }
                        }
                    }
                }
            }

          - visibility_config {
              - cloudwatch_metrics_enabled = true -> null
              - metric_name                = "test-rule-01" -> null
              - sampled_requests_enabled   = true -> null
            }
        }



























      - rule {
          - name     = "test-rule-01" -> null
          - priority = 0 -> null

          - action {

              - count {
                }
            }

          - rule_label {
              - name = "test-namespace02:test-name02" -> null
            }
          - rule_label {
              - name = "test-namespace:test-name" -> null
            }

          - statement {
              - and_statement {
                  - statement {

                      - not_statement {
                          - statement {

                              - label_match_statement {
                                  - key   = "awswaf:managed:aws:bot-control:signal:non_browser_user_agent" -> null
                                  - scope = "LABEL" -> null
                                }
                            }
                        }
                    }
                  - statement {

                      - byte_match_statement {
                          - positional_constraint = "EXACTLY" -> null
                          - search_string         = "test" -> null

                          - field_to_match {

                              - single_header {
                                  - name = "user-agent" -> null
                                }
                            }

                          - text_transformation {
                              - priority = 0 -> null
                              - type     = "NONE" -> null
                            }
                        }
                    }
                }
            }

          - visibility_config {
              - cloudwatch_metrics_enabled = true -> null
              - metric_name                = "test-rule-01" -> null
              - sampled_requests_enabled   = true -> null
            }
        }





~~~
