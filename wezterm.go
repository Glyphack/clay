package main

import (
	"context"
	"embed"
	"fmt"
	"os"
	"path/filepath"
)

//go:embed all:config/wezterm/clay
var weztermClayModule embed.FS

const weztermLoadLua = `local clay_config = require("clay").load()
if clay_config then
	return clay_config
end
`

const weztermStarterLua = `local wezterm = require("wezterm")

local config = wezterm.config_builder()

return config
`

func weztermClayModulePath() string {
	return filepath.Join(ConfigDir, "wezterm", "clay")
}

// weztermConfigPath returns the config file WezTerm reads. It reads ~/.wezterm.lua before
// ~/.config/wezterm/wezterm.lua.
func weztermConfigPath() (string, error) {
	homeConfig := filepath.Join(HomeDir, ".wezterm.lua")
	missing, err := pathMissing(homeConfig)
	if err != nil {
		return "", err
	}
	if !missing {
		return homeConfig, nil
	}
	return filepath.Join(ConfigDir, "wezterm", "wezterm.lua"), nil
}

func enableWeztermModule() error {
	path, err := weztermConfigPath()
	if err != nil {
		return err
	}
	missing, err := pathMissing(path)
	if err != nil {
		return err
	}

	content := weztermStarterLua
	if !missing {
		existing, readErr := os.ReadFile(path)
		if readErr != nil {
			return fmt.Errorf("error reading %s: %w", path, readErr)
		}
		content = string(existing)
	}

	content = putBlock(content, loadMarker, weztermLoadLua, true)

	return writeFile(path, []byte(content), 0o644)
}

func setupWezterm(context.Context) error {
	if err := copyFS(weztermClayModule, weztermClayModulePath()); err != nil {
		return err
	}
	return enableWeztermModule()
}
