import React from 'react';
import { StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';
import { DisplayFont, Palette } from '../../constants/theme';

const PAINTS = [Palette.orange, Palette.yellow, Palette.blue, Palette.green, Palette.pink];

interface BrandMarkProps {
  size?: number;
  style?: StyleProp<ViewStyle>;
}

/**
 * SpotCheck "S on Black" brand mark ("Locate Paint" design system):
 * Deep asphalt black badge, bold stencil S in white with a hard Locate Pink offset shadow,
 * top-right Locate Pink spot marker dot, and the 5-paint strip at the base.
 */
export default function BrandMark({ size = 68, style }: BrandMarkProps) {
  const radius = Math.round(size * 0.26);
  const fontSize = Math.round(size * 0.58);
  const lineHeight = Math.round(size * 0.64);
  const offset = Math.max(2, Math.round(size * 0.045));
  const dotSize = Math.max(8, Math.round(size * 0.14));
  const stripWidth = Math.round(size * 0.68);
  const stripHeight = Math.max(4, Math.round(size * 0.075));

  return (
    <View
      style={[
        styles.badge,
        {
          width: size,
          height: size,
          borderRadius: radius,
        },
        style,
      ]}
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
    >
      {/* Top-right Locate Pink spot marker dot */}
      <View
        style={[
          styles.spotDotOuter,
          {
            width: dotSize,
            height: dotSize,
            borderRadius: dotSize / 2,
            top: Math.round(size * 0.12),
            right: Math.round(size * 0.12),
          },
        ]}
      >
        <View
          style={[
            styles.spotDotInner,
            {
              width: Math.max(4, dotSize - 4),
              height: Math.max(4, dotSize - 4),
              borderRadius: Math.max(2, (dotSize - 4) / 2),
            },
          ]}
        />
      </View>

      {/* Stencil S with hard Locate Pink offset shadow */}
      <View style={styles.letterWrap}>
        <Text
          style={[
            styles.letter,
            styles.letterShadow,
            {
              fontSize,
              lineHeight,
              transform: [{ translateX: offset }, { translateY: offset }, { scaleX: 1.18 }],
            },
          ]}
        >
          S
        </Text>
        <Text
          style={[
            styles.letter,
            styles.letterMain,
            {
              fontSize,
              lineHeight,
              transform: [{ scaleX: 1.18 }],
            },
          ]}
        >
          S
        </Text>
      </View>

      {/* Signature 5-Paint Strip */}
      <View
        style={[
          styles.strip,
          {
            width: stripWidth,
            height: stripHeight,
            borderRadius: stripHeight / 2,
            bottom: Math.round(size * 0.11),
          },
        ]}
      >
        {PAINTS.map((color) => (
          <View key={color} style={[styles.band, { backgroundColor: color }]} />
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    backgroundColor: '#121212',
    borderWidth: 2,
    borderColor: Palette.white,
    alignSelf: 'center',
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
    overflow: 'hidden',
  },
  spotDotOuter: {
    position: 'absolute',
    backgroundColor: Palette.white,
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 3,
  },
  spotDotInner: {
    backgroundColor: Palette.pink,
    borderWidth: 1.5,
    borderColor: '#121212',
  },
  letterWrap: {
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 6,
  },
  letter: {
    fontFamily: DisplayFont.black,
    textAlign: 'center',
    includeFontPadding: false,
  },
  letterShadow: {
    position: 'absolute',
    color: Palette.pink,
  },
  letterMain: {
    color: Palette.white,
    textShadowColor: '#121212',
    textShadowOffset: { width: -1, height: -1 },
    textShadowRadius: 1,
  },
  strip: {
    position: 'absolute',
    flexDirection: 'row',
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: Palette.white,
  },
  band: {
    flex: 1,
  },
});
