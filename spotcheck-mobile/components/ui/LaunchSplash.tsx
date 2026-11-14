import React, { useEffect, useState } from 'react';
import { Animated, Easing, Image, StyleSheet, View } from 'react-native';
import { Palette } from '../../constants/theme';
import { useAuth } from '../../context/AuthContext';

const PAINTS = [Palette.orange, Palette.yellow, Palette.blue, Palette.green, Palette.pink];
const SPLASH_LOGO = require('../../assets/images/splash-icon.png');

/**
 * Branded "Locate Paint" animated launch screen that seamlessly bridges from the native Android
 * splash screen (#141414 + splash-icon.png), animates the 5-paint locate dots and pink route bar
 * while initial session/map setup completes, and fades out smoothly.
 */
export default function LaunchSplash() {
  const { isLoading: authLoading } = useAuth();
  const [minTimePassed, setMinTimePassed] = useState(false);
  const [visible, setVisible] = useState(true);

  const containerOpacity = useState(() => new Animated.Value(1))[0];
  const containerScale = useState(() => new Animated.Value(1))[0];
  const routeProgress = useState(() => new Animated.Value(0))[0];
  const pulseAnim = useState(() => new Animated.Value(0))[0];

  useEffect(() => {
    const loop = Animated.loop(
      Animated.timing(routeProgress, {
        toValue: 1,
        duration: 1100,
        easing: Easing.inOut(Easing.cubic),
        useNativeDriver: true,
      }),
    );
    const pulseLoop = Animated.loop(
      Animated.sequence([
        Animated.timing(pulseAnim, {
          toValue: 1,
          duration: 550,
          easing: Easing.out(Easing.quad),
          useNativeDriver: true,
        }),
        Animated.timing(pulseAnim, {
          toValue: 0,
          duration: 550,
          easing: Easing.in(Easing.quad),
          useNativeDriver: true,
        }),
      ]),
    );
    loop.start();
    pulseLoop.start();

    const minTimer = setTimeout(() => setMinTimePassed(true), 850);
    // Safety cap so a slow/cold backend never blocks the map screen
    const maxTimer = setTimeout(() => setMinTimePassed(true), 1500);

    return () => {
      clearTimeout(minTimer);
      clearTimeout(maxTimer);
      loop.stop();
      pulseLoop.stop();
    };
  }, [pulseAnim, routeProgress]);

  const readyToDismiss = minTimePassed && !authLoading;
  const [forceReady, setForceReady] = useState(false);

  useEffect(() => {
    const cap = setTimeout(() => setForceReady(true), 1400);
    return () => clearTimeout(cap);
  }, []);

  useEffect(() => {
    if (!readyToDismiss && !forceReady) return;

    Animated.parallel([
      Animated.timing(containerOpacity, {
        toValue: 0,
        duration: 300,
        easing: Easing.out(Easing.cubic),
        useNativeDriver: true,
      }),
      Animated.timing(containerScale, {
        toValue: 1.04,
        duration: 300,
        easing: Easing.out(Easing.cubic),
        useNativeDriver: true,
      }),
    ]).start(({ finished }) => {
      if (finished) setVisible(false);
    });
  }, [containerOpacity, containerScale, forceReady, readyToDismiss]);

  if (!visible) return null;

  const barTranslateX = routeProgress.interpolate({
    inputRange: [0, 1],
    outputRange: [-110, 110],
  });

  const ringScale = pulseAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [0.98, 1.03],
  });

  const ringOpacity = pulseAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [0.08, 0.18],
  });

  return (
    <Animated.View
      pointerEvents="none"
      style={[
        styles.overlay,
        {
          opacity: containerOpacity,
          transform: [{ scale: containerScale }],
        },
      ]}
    >
      {/* Subtle pulsing locate radar circle behind the mark */}
      <Animated.View
        style={[
          styles.radarRing,
          {
            opacity: ringOpacity,
            transform: [{ scale: ringScale }],
          },
        ]}
      />

      {/* Centered S logo + SPOTCHECK lockup (matches native splashscreen_logo.png geometry) */}
      <View style={styles.centerBlock}>
        <Image source={SPLASH_LOGO} style={styles.logo} resizeMode="contain" fadeDuration={0} />
      </View>

      {/* Bottom Locate Paint loader: 5 paint dots + sweeping pink route indicator */}
      <View style={styles.loaderArea}>
        <View style={styles.dotsRow}>
          {PAINTS.map((color, idx) => {
            const dotScale = pulseAnim.interpolate({
              inputRange: [0, 0.5, 1],
              outputRange: idx % 2 === 0 ? [1, 1.22, 1] : [1.18, 0.95, 1.18],
            });
            return (
              <Animated.View
                key={color}
                style={[
                  styles.paintDot,
                  {
                    backgroundColor: color,
                    transform: [{ scale: dotScale }],
                  },
                ]}
              />
            );
          })}
        </View>

        <View style={styles.routeTrack}>
          <Animated.View
            style={[
              styles.routeRunner,
              {
                transform: [{ translateX: barTranslateX }],
              },
            ]}
          />
        </View>
      </View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  overlay: {
    position: 'absolute',
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
    backgroundColor: '#141414',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 9999,
  },
  radarRing: {
    position: 'absolute',
    width: 290,
    height: 290,
    borderRadius: 145,
    borderWidth: 2,
    borderColor: Palette.white,
    borderStyle: 'dashed',
  },
  centerBlock: {
    width: 220,
    height: 220,
    alignItems: 'center',
    justifyContent: 'center',
  },
  logo: {
    width: 220,
    height: 220,
  },
  loaderArea: {
    position: 'absolute',
    bottom: 76,
    alignItems: 'center',
    gap: 14,
  },
  dotsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  paintDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    borderWidth: 1.5,
    borderColor: Palette.white,
  },
  routeTrack: {
    width: 148,
    height: 6,
    borderRadius: 3,
    backgroundColor: '#262626',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.22)',
    overflow: 'hidden',
  },
  routeRunner: {
    width: 68,
    height: '100%',
    borderRadius: 3,
    backgroundColor: Palette.pink,
  },
});
