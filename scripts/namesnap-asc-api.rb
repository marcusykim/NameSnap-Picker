#!/usr/local/opt/ruby/bin/ruby

require "json"
require "net/http"
require "spaceship"
require "uri"

APP_ID = "6759588637"
KEY_ID = "4HA95XB6S5"
ISSUER_ID = "67c52852-b22f-4e49-ad81-df53bf4476fb"
KEY_PATH = "/Users/marcuskim/.AuthKey_4HA95XB6S5.p8"

token = Spaceship::ConnectAPI::Token.create(
  key_id: KEY_ID,
  issuer_id: ISSUER_ID,
  filepath: KEY_PATH
)

def request(token, method, path, body: nil, allow_not_found: false)
  uri = URI("https://api.appstoreconnect.apple.com#{path}")
  request_class = {
    get: Net::HTTP::Get,
    post: Net::HTTP::Post,
    patch: Net::HTTP::Patch,
    delete: Net::HTTP::Delete
  }.fetch(method)
  req = request_class.new(uri)
  req["Authorization"] = "Bearer #{token.text}"
  req["Content-Type"] = "application/json" if body
  req.body = JSON.generate(body) if body
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
  parsed = response.body.to_s.empty? ? {} : JSON.parse(response.body)
  return {} if allow_not_found && response.code.to_i == 404
  unless response.code.to_i.between?(200, 299)
    details = Array(parsed["errors"]).map do |error|
      [error["status"], error["code"], error["title"], error["detail"]].compact.join(" · ")
    end
    abort("App Store Connect API #{response.code}: #{details.join(" | ")}")
  end
  parsed
end

def beta_groups(token)
  request(token, :get, "/v1/betaGroups?filter%5Bapp%5D=#{APP_ID}&limit=200").fetch("data", [])
end

def beta_group_builds(token, group_id)
  request(token, :get, "/v1/betaGroups/#{group_id}/builds?limit=200").fetch("data", [])
end

def build_for(token, build_number)
  request(
    token,
    :get,
    "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=#{URI.encode_www_form_component(build_number)}&sort=-uploadedDate&limit=1"
  ).fetch("data", []).first
end

def add_build_to_group(token, group_id, build_id)
  request(
    token,
    :post,
    "/v1/betaGroups/#{group_id}/relationships/builds",
    body: { data: [{ type: "builds", id: build_id }] }
  )
end

def submit_build_for_beta_review(token, build_id)
  request(
    token,
    :post,
    "/v1/betaAppReviewSubmissions",
    body: {
      data: {
        type: "betaAppReviewSubmissions",
        relationships: {
          build: { data: { type: "builds", id: build_id } }
        }
      }
    }
  ).fetch("data")
end

def app_store_versions(token)
  request(
    token,
    :get,
    "/v1/apps/#{APP_ID}/appStoreVersions?filter%5Bplatform%5D=IOS&limit=20"
  ).fetch("data", [])
end

def version_submission(token, version_id)
  request(
    token,
    :get,
    "/v1/appStoreVersions/#{version_id}/relationships/appStoreVersionSubmission",
    allow_not_found: true
  )["data"]
end

def review_submissions(token)
  request(token, :get, "/v1/apps/#{APP_ID}/reviewSubmissions?limit=200").fetch("data", [])
end

case ARGV.fetch(0, "build-status")
when "build-status"
  build_number = ARGV.fetch(1, "13")
  build = build_for(token, build_number)
  puts JSON.pretty_generate(
    build: build && {
      id: build["id"],
      build_number: build.dig("attributes", "version"),
      processing_state: build.dig("attributes", "processingState"),
      uploaded_date: build.dig("attributes", "uploadedDate"),
      expired: build.dig("attributes", "expired")
    }
  )
when "distribute-build"
  build_number = ARGV.fetch(1)
  build = build_for(token, build_number)
  abort("Build #{build_number} is not available in App Store Connect") unless build
  abort("Build #{build_number} is not valid") unless build.dig("attributes", "processingState") == "VALID"

  groups = beta_groups(token).select { |group| group.dig("attributes", "isInternalGroup") }
  abort("NameSnap has no internal TestFlight group") if groups.empty?
  groups.each do |group|
    next if beta_group_builds(token, group.fetch("id")).any? { |candidate| candidate["id"] == build["id"] }

    add_build_to_group(token, group.fetch("id"), build.fetch("id"))
  end
  puts JSON.pretty_generate(
    build_number: build_number,
    build_id: build["id"],
    groups: groups.map { |group| { id: group["id"], name: group.dig("attributes", "name") } }
  )
when "testflight-status"
  build_number = ARGV.fetch(1, "13")
  puts JSON.pretty_generate(
    groups: beta_groups(token).map do |group|
      {
        id: group["id"],
        name: group.dig("attributes", "name"),
        internal: group.dig("attributes", "isInternalGroup"),
        builds: beta_group_builds(token, group.fetch("id")).filter_map do |build|
          next unless build.dig("attributes", "version") == build_number

          {
            id: build["id"],
            build_number: build_number,
            processing_state: build.dig("attributes", "processingState"),
            expired: build.dig("attributes", "expired")
          }
        end
      }
    end
  )
when "public-beta-status"
  build_number = ARGV.fetch(1, "24")
  build = build_for(token, build_number)
  abort("Build #{build_number} is not available in App Store Connect") unless build
  review_submission = request(
    token,
    :get,
    "/v1/builds/#{build.fetch("id")}/betaAppReviewSubmission",
    allow_not_found: true
  )["data"]
  puts JSON.pretty_generate(
    build: {
      id: build["id"],
      build_number: build.dig("attributes", "version"),
      processing_state: build.dig("attributes", "processingState"),
      expired: build.dig("attributes", "expired")
    },
    beta_review_submission: review_submission && {
      id: review_submission["id"],
      state: review_submission.dig("attributes", "betaReviewState")
    },
    external_groups: beta_groups(token).reject { |group| group.dig("attributes", "isInternalGroup") }.map do |group|
      {
        id: group["id"],
        name: group.dig("attributes", "name"),
        public_link_enabled: group.dig("attributes", "publicLinkEnabled"),
        public_link: group.dig("attributes", "publicLink"),
        public_link_limit_enabled: group.dig("attributes", "publicLinkLimitEnabled"),
        public_link_limit: group.dig("attributes", "publicLinkLimit"),
        has_access_to_all_builds: group.dig("attributes", "hasAccessToAllBuilds"),
        builds: beta_group_builds(token, group.fetch("id")).map do |candidate|
          {
            id: candidate["id"],
            build_number: candidate.dig("attributes", "version"),
            processing_state: candidate.dig("attributes", "processingState"),
            expired: candidate.dig("attributes", "expired")
          }
        end
      }
    end
  )
when "enable-public-beta"
  build_number = ARGV.fetch(1, "24")
  build = build_for(token, build_number)
  abort("Build #{build_number} is not available in App Store Connect") unless build
  abort("Build #{build_number} is not valid") unless build.dig("attributes", "processingState") == "VALID"
  abort("Build #{build_number} is expired") if build.dig("attributes", "expired")

  external_groups = beta_groups(token).reject { |group| group.dig("attributes", "isInternalGroup") }
  group = external_groups.find { |candidate| candidate.dig("attributes", "publicLinkEnabled") }
  abort("NameSnap has no external TestFlight group with a public link") unless group

  group_builds = beta_group_builds(token, group.fetch("id"))
  unless group_builds.any? { |candidate| candidate["id"] == build["id"] }
    add_build_to_group(token, group.fetch("id"), build.fetch("id"))
  end

  review_submission = request(
    token,
    :get,
    "/v1/builds/#{build.fetch("id")}/betaAppReviewSubmission",
    allow_not_found: true
  )["data"]
  review_submission ||= submit_build_for_beta_review(token, build.fetch("id"))

  refreshed_group = request(token, :get, "/v1/betaGroups/#{group.fetch("id")}").fetch("data")
  puts JSON.pretty_generate(
    build_number: build_number,
    build_id: build["id"],
    group_id: refreshed_group["id"],
    group_name: refreshed_group.dig("attributes", "name"),
    public_link_enabled: refreshed_group.dig("attributes", "publicLinkEnabled"),
    public_link: refreshed_group.dig("attributes", "publicLink"),
    beta_review_submission: {
      id: review_submission["id"],
      state: review_submission.dig("attributes", "betaReviewState")
    }
  )
when "submission-status"
  puts JSON.pretty_generate(
    review_submissions: review_submissions(token).map do |submission|
      {
        id: submission["id"],
        state: submission.dig("attributes", "state"),
        submitted_date: submission.dig("attributes", "submittedDate"),
        platform: submission.dig("attributes", "platform")
      }
    end,
    versions: app_store_versions(token).map do |version|
      {
        id: version["id"],
        version: version.dig("attributes", "versionString"),
        state: version.dig("attributes", "appStoreState"),
        submission: version_submission(token, version.fetch("id"))
      }
    end
  )
when "visual-assets-status"
  version_string = ARGV.fetch(1, "2.0")
  locale = ARGV.fetch(2, "en-US")
  version = app_store_versions(token).find do |candidate|
    candidate.dig("attributes", "versionString") == version_string
  end
  abort("NameSnap version #{version_string} is not available in App Store Connect") unless version

  localizations = request(
    token,
    :get,
    "/v1/appStoreVersions/#{version.fetch("id")}/appStoreVersionLocalizations?limit=200"
  ).fetch("data", [])
  localization = localizations.find { |candidate| candidate.dig("attributes", "locale") == locale }
  abort("NameSnap version #{version_string} has no #{locale} localization") unless localization

  screenshot_response = request(
    token,
    :get,
    "/v1/appStoreVersionLocalizations/#{localization.fetch("id")}/appScreenshotSets?include=appScreenshots&limit=200"
  )
  preview_response = request(
    token,
    :get,
    "/v1/appStoreVersionLocalizations/#{localization.fetch("id")}/appPreviewSets?include=appPreviews&limit=200"
  )

  screenshot_names = screenshot_response.fetch("included", []).filter_map do |asset|
    next unless asset["type"] == "appScreenshots"
    {
      id: asset["id"],
      file_name: asset.dig("attributes", "fileName"),
      delivery_state: asset.dig("attributes", "assetDeliveryState", "state")
    }
  end
  preview_names = preview_response.fetch("included", []).filter_map do |asset|
    next unless asset["type"] == "appPreviews"
    {
      file_name: asset.dig("attributes", "fileName"),
      delivery_state: asset.dig("attributes", "videoDeliveryState", "state")
    }
  end

  puts JSON.pretty_generate(
    version: version_string,
    version_state: version.dig("attributes", "appStoreState"),
    locale: locale,
    screenshot_sets: screenshot_response.fetch("data", []).map do |set|
      {
        display_type: set.dig("attributes", "screenshotDisplayType"),
        screenshot_count: Array(set.dig("relationships", "appScreenshots", "data")).count
      }
    end,
    screenshots: screenshot_names.sort_by { |asset| asset[:file_name].to_s },
    preview_sets: preview_response.fetch("data", []).map do |set|
      {
        preview_type: set.dig("attributes", "previewType"),
        preview_count: Array(set.dig("relationships", "appPreviews", "data")).count
      }
    end,
    previews: preview_names.sort_by { |asset| asset[:file_name].to_s }
  )
when "dedupe-visual-assets"
  version_string = ARGV.fetch(1, "2.0")
  locale = ARGV.fetch(2, "en-US")
  version = app_store_versions(token).find do |candidate|
    candidate.dig("attributes", "versionString") == version_string
  end
  abort("NameSnap version #{version_string} is not available in App Store Connect") unless version

  localizations = request(
    token,
    :get,
    "/v1/appStoreVersions/#{version.fetch("id")}/appStoreVersionLocalizations?limit=200"
  ).fetch("data", [])
  localization = localizations.find { |candidate| candidate.dig("attributes", "locale") == locale }
  abort("NameSnap version #{version_string} has no #{locale} localization") unless localization

  screenshot_response = request(
    token,
    :get,
    "/v1/appStoreVersionLocalizations/#{localization.fetch("id")}/appScreenshotSets?include=appScreenshots&limit=200"
  )
  assets_by_id = screenshot_response.fetch("included", []).each_with_object({}) do |asset, result|
    result[asset["id"]] = asset if asset["type"] == "appScreenshots"
  end

  deleted = []
  kept_sets = screenshot_response.fetch("data", []).map do |set|
    assets = Array(set.dig("relationships", "appScreenshots", "data")).filter_map do |relationship|
      assets_by_id[relationship["id"]]
    end
    kept = assets.group_by { |asset| asset.dig("attributes", "fileName") }.sort.flat_map do |_file_name, candidates|
      ordered = candidates.sort_by do |asset|
        asset.dig("attributes", "assetDeliveryState", "state") == "COMPLETE" ? 0 : 1
      end
      ordered.drop(1).each do |duplicate|
        request(token, :delete, "/v1/appScreenshots/#{duplicate.fetch("id")}")
        deleted << {
          id: duplicate["id"],
          file_name: duplicate.dig("attributes", "fileName")
        }
      end
      ordered.first(1)
    end

    request(
      token,
      :patch,
      "/v1/appScreenshotSets/#{set.fetch("id")}/relationships/appScreenshots",
      body: {
        data: kept.sort_by { |asset| asset.dig("attributes", "fileName").to_s }.map do |asset|
          { type: "appScreenshots", id: asset.fetch("id") }
        end
      }
    )
    {
      display_type: set.dig("attributes", "screenshotDisplayType"),
      kept: kept.map { |asset| asset.dig("attributes", "fileName") }.sort
    }
  end

  puts JSON.pretty_generate(
    version: version_string,
    locale: locale,
    deleted_duplicates: deleted,
    screenshot_sets: kept_sets
  )
when "cancel-submission"
  submission = review_submissions(token).find do |candidate|
    %w[WAITING_FOR_REVIEW IN_REVIEW].include?(candidate.dig("attributes", "state"))
  end
  abort("NameSnap has no review submission that can be canceled") unless submission

  updated = request(
    token,
    :patch,
    "/v1/reviewSubmissions/#{submission.fetch("id")}",
    body: {
      data: {
        type: "reviewSubmissions",
        id: submission.fetch("id"),
        attributes: { canceled: true }
      }
    }
  ).fetch("data")
  puts JSON.pretty_generate(
    submission_id: submission["id"],
    previous_state: submission.dig("attributes", "state"),
    current_state: updated.dig("attributes", "state"),
    canceled: true
  )
else
  abort("Unknown command: #{ARGV[0]}")
end
