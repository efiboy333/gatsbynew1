name: Slack Notification

on:
  workflow_call:
    inputs:
      STATUS:
        required: true
        type: string
    secrets:
      SLACK_CHANNEL_ID:
        required: true
      SLACK_BOT_TOKEN:
        required: true

jobs:
  send-slack-notification:
    runs-on: ubuntu-latest
    steps:

      - name: Print out status sent
        run: echo "${{ inputs.STATUS }}"

      - name: Execute Bash Script
        run: |
          # Define the bash script inline
          script='#!/bin/bash
          input_string="${{ inputs.STATUS }}"
          read -ra array <<< "$input_string"
          status="success"
          style="primary"
          for element in "${array[@]}"
          do
              if [ "$element" != "success" ]; then
                  status="failure"
                  style="danger"
                  break
              fi
          done
          echo "status=$status" >> $GITHUB_ENV
          echo "style=$style" >> $GITHUB_ENV'

          # Execute the script
          bash -c "$script"

      - name: Print out Status Environment Variable
        run: |
          # Use the status environment variable in this step
          echo "Status: ${{ env.status }}"

      - name: Generate Run Logs Url
        run: |
          logUrl="https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}"
          echo "Build Log URL: $logUrl"
          echo "logUrl=$logUrl" >> $GITHUB_ENV

      - name: Post to a Slack channel
        id: slack
        if: steps.build-status.outputs.exit_code == 0
        uses: slackapi/slack-github-action@v1.22.0
        with:
          channel-id: ${{ secrets.SLACK_PR_CHANNEL_ID }}
          payload: |
            {
              "text": "Build result",
              "blocks": [
                      {
                        "type": "section",
                        "text": {
                          "type": "plain_text",
                          "text": "Hi Team :wave: \n ${{ github.repository }} Build Status:"
                        }
                      },
                      {
                        "type": "divider"
                      },
                      {
                        "type": "section",
                        "text": {
                          "type": "mrkdwn",
                          "text": "*Status:* ${{ env.status }}\n*Repo:* <https://github.com/madewithkoji/${{ github.repository }}|${{ github.repository }}>"
                        },
                      "accessory": {
                        "type": "button",
                        "text": {
                          "type": "plain_text",
                          "text": "View Build History"
                        },
                        "value": "Cloudside",
                        "style": "${{ env.style }}",
                        "url": "${{ env.logUrl }}",
                        "action_id": "button-action"
                      }
                      },
                      {
                        "type": "divider"
                      },
                      {
                        "type": "section",
                        "text": {
                          "type": "mrkdwn",
                          "text": "*Commit Ref:* ${{ github.event.head_commit.url }}\n*Commit Message:* ${{ github.event.head_commit.message }}\n*Github Actor:* ${{ github.actor }}"
                        }
                      },
                      {
                        "type": "divider"
                      }
                    ]
            }
        env:
          SLACK_BOT_TOKEN: ${{ secrets.SLACK_BOT_TOKEN }}
