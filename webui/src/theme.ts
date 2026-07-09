import { exec } from "kernelsu-alt";
import type themeJson from "../public/theme.json";

type ThemeData = typeof themeJson;
type ThemeScheme = ThemeData["schemes"]["light"];

let cachedThemeData: ThemeData | null = null;

const resourceForRole: ThemeScheme = {
  primary: "primary",
  surfaceTint: "primary",
  onPrimary: "on_primary",
  primaryContainer: "primary_container",
  onPrimaryContainer: "on_primary_container",
  secondary: "secondary",
  onSecondary: "on_secondary",
  secondaryContainer: "secondary_container",
  onSecondaryContainer: "on_secondary_container",
  tertiary: "tertiary",
  onTertiary: "on_tertiary",
  tertiaryContainer: "tertiary_container",
  onTertiaryContainer: "on_tertiary_container",
  error: "error",
  onError: "on_error",
  errorContainer: "error_container",
  onErrorContainer: "on_error_container",
  background: "background",
  onBackground: "on_background",
  surface: "surface",
  onSurface: "on_surface",
  surfaceVariant: "surface_variant",
  onSurfaceVariant: "on_surface_variant",
  outline: "outline",
  outlineVariant: "outline_variant",
  shadow: "shadow",
  scrim: "scrim",
  inverseSurface: "text_primary_inverse",
  inverseOnSurface: "text_hint_inverse",
  inversePrimary: "primary",
  primaryFixed: "primary_fixed",
  primaryFixedDim: "primary_fixed_dim",
  onPrimaryFixed: "on_primary_fixed",
  onPrimaryFixedVariant: "on_primary_fixed_variant",
  secondaryFixed: "secondary_fixed",
  secondaryFixedDim: "secondary_fixed_dim",
  onSecondaryFixed: "on_secondary_fixed",
  onSecondaryFixedVariant: "on_secondary_fixed_variant",
  tertiaryFixed: "tertiary_fixed",
  tertiaryFixedDim: "tertiary_fixed_dim",
  onTertiaryFixed: "on_tertiary_fixed",
  onTertiaryFixedVariant: "on_tertiary_fixed_variant",
  surfaceDim: "surface_dim",
  surfaceBright: "surface_bright",
  surfaceContainerLowest: "surface_container_lowest",
  surfaceContainerLow: "surface_container_low",
  surfaceContainer: "surface_container",
  surfaceContainerHigh: "surface_container_high",
  surfaceContainerHighest: "surface_container_highest",
};

async function lookupDynamicColors() {
  const { errno, stdout } = await exec(`
    for overlay in $(cmd overlay list --user current android | sed -n "s/^\\[x\\] //p" | grep :); do
      cmd overlay dump "$overlay" 2>/dev/null
    done
  `);
  if (errno !== 0) return null;

  const colors: Record<string, string> = {};
  for (const line of stdout.split("\n")) {
    const match = line.match(/color 0x([0-9a-fA-F]{8}) \(color\/system_([^)]+)\)/);
    if (match) colors[match[2]] = `#${match[1].slice(-6)}`;
  }

  return Object.keys(colors).length ? colors : null;
}

const getObjectKeys = <T extends Record<string, any>>(
  object: T,
): (keyof T)[] => {
  return Object.keys(object);
};

export async function loadThemeData() {
  if (cachedThemeData) return cachedThemeData;

  const response = await fetch("theme.json");
  const themeData: ThemeData = await response.json();
  cachedThemeData = themeData;

  try {
    const colors = await lookupDynamicColors();
    if (!colors) return cachedThemeData;

    for (const scheme of ["light", "dark"] as const) {
      for (const key of getObjectKeys(cachedThemeData.schemes[scheme])) {
        const resource = resourceForRole[key];

        const color = colors[`${resource}_${scheme}`] ?? colors[resource];
        if (color) cachedThemeData.schemes[scheme][key] = color;
      }
    }
  } catch (error) {
    console.error("Error loading Monet colors:", error);
  }

  return cachedThemeData;
}
