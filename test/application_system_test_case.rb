require "test_helper"
require "capybara/playwright"

# Set up Playwright browser compatibility for Nix-managed browsers.
#
# The playwright-ruby-client gem expects specific browser revision directories
# (e.g., chromium-1208), but Nix may provide a different revision (e.g., chromium-1200).
# We create a compatibility layer with symlinks so Playwright can find the browsers.
module PlaywrightNixCompat
  COMPAT_DIR = Rails.root.join("tmp", "playwright-browsers")
  @setup_failed = false
  @setup_error = nil

  class << self
    attr_reader :setup_failed, :setup_error

    def setup!
      return unless nix_browsers_path

      create_compatibility_symlinks unless compatibility_dir_valid?

      # Always set the ENV to point to our compatibility directory
      ENV["PLAYWRIGHT_BROWSERS_PATH"] = COMPAT_DIR.to_s
    end

    private

    def nix_browsers_path
      @nix_browsers_path ||= ENV["PLAYWRIGHT_BROWSERS_PATH"]
    end

    def compatibility_dir_valid?
      # Check if we've already set up the compat dir
      COMPAT_DIR.exist? && COMPAT_DIR.children.any?
    end

    def create_compatibility_symlinks
      FileUtils.mkdir_p(COMPAT_DIR)
      log "Creating browser symlinks in #{COMPAT_DIR}"

      # Find all browser directories in the Nix store
      Dir.glob(File.join(nix_browsers_path, "*")).each do |browser_dir|
        name = File.basename(browser_dir)

        # Create a symlink with the original name
        link_path = COMPAT_DIR.join(name)
        unless link_path.exist?
          FileUtils.ln_sf(browser_dir, link_path)
          log "  Linked #{name}"
        end

        # Also create symlinks for common revision mismatches
        # e.g., if we have chromium-1200, also link chromium-1208
        create_revision_aliases(browser_dir, name)
      end
    rescue SystemCallError => e
      @setup_failed = true
      @setup_error = "#{e.class}: #{e.message}"
      warn "[PlaywrightNixCompat] Failed to create browser symlinks: #{@setup_error}"
      warn "[PlaywrightNixCompat] System tests may fail with confusing browser errors."
    end

    def create_revision_aliases(browser_dir, name)
      # Match patterns like chromium-1200 or chromium_headless_shell-1200
      return unless name =~ /^(.+)-(\d+)$/

      browser_name = Regexp.last_match(1)
      revision = Regexp.last_match(2).to_i

      # Create aliases for nearby revisions (common version mismatches)
      [ -10, -5, 5, 8, 10 ].each do |offset|
        alias_revision = revision + offset
        alias_name = "#{browser_name}-#{alias_revision}"
        alias_path = COMPAT_DIR.join(alias_name)

        unless alias_path.exist?
          FileUtils.ln_sf(browser_dir, alias_path)
          log "  Aliased #{alias_name} -> #{name}"
        end
      end
    end

    def log(message)
      return unless ENV["DEBUG_PLAYWRIGHT_NIX"] || ENV["VERBOSE"]
      puts "[PlaywrightNixCompat] #{message}"
    end
  end
end

PlaywrightNixCompat.setup!

# Configure Capybara server to bind to 127.0.0.1 so Playwright can connect
Capybara.server_host = "127.0.0.1"
Capybara.app_host = "http://127.0.0.1"

Capybara.register_driver :playwright do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: ENV.fetch("PLAYWRIGHT_BROWSER", "chromium").to_sym,
    headless: ENV["CI"].present? || ENV["PLAYWRIGHT_HEADLESS"].present?
  )
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :playwright, screen_size: [ 1400, 1400 ]

  # Sign in a user for system tests using the actual sign-in form.
  # This differs from SignInHelper#sign_in_as which uses POST requests
  # directly - system tests need to use Capybara to interact with the browser.
  def sign_in_as(user)
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_on "Sign in"

    # Wait for navigation away from login page
    # Capybara will wait up to default_max_wait_time for this
    assert_no_current_path("/session/new", wait: 5)
  end
end
