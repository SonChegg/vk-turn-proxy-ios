import { useState } from "react";
import {
  Modal,
  Pressable,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  View
} from "react-native";

import type { InviteService } from "../lib/proxyConfig";
import { useProxyController } from "../hooks/useProxyController";

const inviteOptions: Array<{ key: InviteService; label: string }> = [
  { key: "vk", label: "VK Calls" },
  { key: "yandex", label: "Yandex Telemost" }
];

const guideCards = [
  {
    title: "1. Сервер",
    text: "Запустите серверную часть на VPS и направьте её в локальный WireGuard/Hysteria порт.",
    code: "./server-linux-amd64 -listen 0.0.0.0:56000 -connect 127.0.0.1:<порт_wg>"
  },
  {
    title: "2. WireGuard на iPhone",
    text: "В peer-конфиге замените endpoint на localhost и уменьшите MTU.",
    code: "Endpoint = 127.0.0.1:9000\nMTU = 1280"
  },
  {
    title: "3. Что ввести в приложении",
    text: "Укажите адрес VPS и ссылку VK Calls. Для первого запуска чаще всего хватает стандартного режима.",
    code: "Peer: 1.2.3.4:56000\nLink: https://vk.com/call/join/...\nStreams: 8\nUse UDP: on\nListen: 127.0.0.1:9000"
  },
  {
    title: "Важно для iOS",
    text: "Начинайте со split-tunnel WireGuard-конфига, а не с полного 0.0.0.0/0, чтобы не загнать трафик самого proxy-клиента в цикл.",
    code: null
  }
] as const;

export function MainScreen() {
  const model = useProxyController();
  const [showGuide, setShowGuide] = useState(false);

  return (
    <SafeAreaView style={styles.safeArea}>
      <View style={styles.background}>
        <View style={[styles.blob, styles.blobPrimary]} />
        <View style={[styles.blob, styles.blobSecondary]} />
        <View style={[styles.blob, styles.blobAccent]} />
      </View>

      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.headerRow}>
          <View>
            <Text style={styles.title}>VK TURN Proxy</Text>
            <Text style={styles.subtitle}>Expo development build с локальным iOS bridge</Text>
          </View>

          <Pressable style={styles.guideButton} onPress={() => setShowGuide(true)}>
            <Text style={styles.guideButtonText}>Сервер</Text>
          </Pressable>
        </View>

        <SectionCard>
          <View style={styles.rowSpace}>
            <Text style={styles.cardTitle}>{model.isRunning ? "Proxy запущен" : "Proxy остановлен"}</Text>
            <View style={[styles.pill, model.isRunning ? styles.runningPill : styles.idlePill]}>
              <Text style={styles.pillText}>{model.isRunning ? "RUNNING" : "IDLE"}</Text>
            </View>
          </View>
          <Text style={styles.mutedText}>
            Для WireGuard на iOS используй endpoint `127.0.0.1:9000` и `MTU = 1280`.
          </Text>
        </SectionCard>

        {!model.bridgeAvailable ? (
          <SectionCard tint={styles.warningCard}>
            <Text style={styles.cardTitle}>Bridge пока не подключен</Text>
            <Text style={styles.mutedText}>
              Expo UI уже работает, но настоящий runtime включится только после сборки `VkTurnCore.xcframework`
              и подготовки development build.
            </Text>
          </SectionCard>
        ) : null}

        <SectionCard>
          <Text style={styles.cardTitle}>Режим запуска</Text>
          <View style={styles.toggleRow}>
            <View style={styles.toggleTextWrap}>
              <Text style={styles.toggleTitle}>Raw-команда</Text>
              <Text style={styles.toggleCaption}>Повторяет Android-режим ручных аргументов.</Text>
            </View>
            <Switch
              value={model.config.rawMode}
              onValueChange={(value) => model.updateField("rawMode", value)}
              trackColor={{ false: "#31414b", true: "#1cc2b5" }}
              thumbColor="#f7fafc"
            />
          </View>
        </SectionCard>

        {model.config.rawMode ? (
          <SectionCard>
            <Text style={styles.cardTitle}>Raw-команда</Text>
            <Text style={styles.mutedText}>
              Можно вставлять почти тот же набор флагов, что в Android. Если в начале указать `./client`,
              оно будет отброшено автоматически.
            </Text>
            <TextInput
              multiline
              value={model.config.rawCommand}
              onChangeText={(value) => model.updateField("rawCommand", value)}
              style={[styles.input, styles.editor]}
              placeholder="./client -peer 1.2.3.4:56000 -vk-link https://vk.com/call/join/..."
              placeholderTextColor="#8fa2ab"
              autoCapitalize="none"
              autoCorrect={false}
            />
          </SectionCard>
        ) : (
          <SectionCard>
            <Text style={styles.cardTitle}>Параметры</Text>

            <FieldLabel text="Тип ссылки" />
            <View style={styles.segmentRow}>
              {inviteOptions.map((option) => {
                const active = model.config.inviteService === option.key;
                return (
                  <Pressable
                    key={option.key}
                    style={[styles.segmentButton, active ? styles.segmentButtonActive : null]}
                    onPress={() => model.updateField("inviteService", option.key)}
                  >
                    <Text style={[styles.segmentButtonText, active ? styles.segmentButtonTextActive : null]}>
                      {option.label}
                    </Text>
                  </Pressable>
                );
              })}
            </View>

            <LabeledInput
              label="Peer (IP:Port сервера)"
              value={model.config.peer}
              placeholder="11.22.33.44:56000"
              onChangeText={(value) => model.updateField("peer", value)}
            />
            <LabeledInput
              label="Ссылка на звонок"
              value={model.config.link}
              placeholder="https://vk.com/call/join/..."
              onChangeText={(value) => model.updateField("link", value)}
            />
            <LabeledInput
              label="Локальный endpoint"
              value={model.config.listen}
              placeholder="127.0.0.1:9000"
              onChangeText={(value) => model.updateField("listen", value)}
            />
            <LabeledInput
              label="Override TURN IP"
              value={model.config.turnHost}
              placeholder="необязательно"
              onChangeText={(value) => model.updateField("turnHost", value)}
            />
            <LabeledInput
              label="Override TURN Port"
              value={model.config.turnPort}
              placeholder="необязательно"
              onChangeText={(value) => model.updateField("turnPort", value)}
            />

            <FieldLabel text="Потоки" />
            <View style={styles.stepperCard}>
              <Text style={styles.stepperValue}>{model.config.streams}</Text>
              <View style={styles.stepperButtons}>
                <MiniButton
                  label="-"
                  onPress={() =>
                    model.updateField("streams", Math.max(1, model.config.streams - 1))
                  }
                />
                <MiniButton
                  label="+"
                  onPress={() =>
                    model.updateField("streams", Math.min(16, model.config.streams + 1))
                  }
                />
              </View>
            </View>

            <ToggleRow
              title="Использовать UDP (-udp)"
              value={model.config.useUDP}
              onValueChange={(value) => model.updateField("useUDP", value)}
            />
            <ToggleRow
              title="Без DTLS обфускации (-no-dtls)"
              value={model.config.noDTLS}
              onValueChange={(value) => model.updateField("noDTLS", value)}
            />
          </SectionCard>
        )}

        <SectionCard>
          {model.lastError ? <Text style={styles.errorText}>{model.lastError}</Text> : null}

          <PrimaryButton
            label={model.isRunning ? "Остановить Proxy" : "Запустить Proxy"}
            tint={model.isRunning ? "#c14f5c" : "#1f9d66"}
            onPress={model.toggleProxy}
          />

          <View style={styles.secondaryActions}>
            <SecondaryButton label="Сбросить" onPress={model.resetConfiguration} />
            <SecondaryButton label="Скопировать логи" onPress={() => void model.copyLogs()} />
          </View>
        </SectionCard>

        <SectionCard tint={styles.logCard}>
          <View style={styles.rowSpace}>
            <Text style={styles.cardTitle}>Логи</Text>
            <Text style={styles.logCount}>{model.logs.length}</Text>
          </View>
          <View style={styles.logBox}>
            <Text style={styles.logText}>{model.logsText}</Text>
          </View>
        </SectionCard>
      </ScrollView>

      <Modal animationType="slide" visible={showGuide} onRequestClose={() => setShowGuide(false)}>
        <SafeAreaView style={styles.modalSafeArea}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>Настройка</Text>
            <Pressable style={styles.guideButton} onPress={() => setShowGuide(false)}>
              <Text style={styles.guideButtonText}>Готово</Text>
            </Pressable>
          </View>
          <ScrollView contentContainerStyle={styles.modalContent}>
            {guideCards.map((card) => (
              <SectionCard key={card.title}>
                <Text style={styles.cardTitle}>{card.title}</Text>
                <Text style={styles.mutedText}>{card.text}</Text>
                {card.code ? (
                  <View style={styles.logBox}>
                    <Text style={styles.logText}>{card.code}</Text>
                  </View>
                ) : null}
              </SectionCard>
            ))}
          </ScrollView>
        </SafeAreaView>
      </Modal>
    </SafeAreaView>
  );
}

function SectionCard({
  children,
  tint
}: {
  children: React.ReactNode;
  tint?: object;
}) {
  return <View style={[styles.sectionCard, tint]}>{children}</View>;
}

function FieldLabel({ text }: { text: string }) {
  return <Text style={styles.fieldLabel}>{text}</Text>;
}

function LabeledInput({
  label,
  onChangeText,
  placeholder,
  value
}: {
  label: string;
  onChangeText: (value: string) => void;
  placeholder: string;
  value: string;
}) {
  return (
    <View style={styles.fieldWrap}>
      <FieldLabel text={label} />
      <TextInput
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColor="#8fa2ab"
        autoCapitalize="none"
        autoCorrect={false}
        style={styles.input}
      />
    </View>
  );
}

function ToggleRow({
  onValueChange,
  title,
  value
}: {
  onValueChange: (value: boolean) => void;
  title: string;
  value: boolean;
}) {
  return (
    <View style={styles.toggleRow}>
      <Text style={styles.toggleTitle}>{title}</Text>
      <Switch
        value={value}
        onValueChange={onValueChange}
        trackColor={{ false: "#31414b", true: "#1cc2b5" }}
        thumbColor="#f7fafc"
      />
    </View>
  );
}

function PrimaryButton({
  label,
  onPress,
  tint
}: {
  label: string;
  onPress: () => void;
  tint: string;
}) {
  return (
    <Pressable style={[styles.primaryButton, { backgroundColor: tint }]} onPress={onPress}>
      <Text style={styles.primaryButtonText}>{label}</Text>
    </Pressable>
  );
}

function SecondaryButton({ label, onPress }: { label: string; onPress: () => void }) {
  return (
    <Pressable style={styles.secondaryButton} onPress={onPress}>
      <Text style={styles.secondaryButtonText}>{label}</Text>
    </Pressable>
  );
}

function MiniButton({ label, onPress }: { label: string; onPress: () => void }) {
  return (
    <Pressable style={styles.miniButton} onPress={onPress}>
      <Text style={styles.miniButtonText}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: "#091018"
  },
  background: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "#091018"
  },
  blob: {
    position: "absolute",
    borderRadius: 999,
    opacity: 0.38
  },
  blobPrimary: {
    width: 260,
    height: 260,
    backgroundColor: "#19364a",
    top: -40,
    left: -60
  },
  blobSecondary: {
    width: 300,
    height: 300,
    backgroundColor: "#1a4f48",
    top: 180,
    right: -120
  },
  blobAccent: {
    width: 280,
    height: 280,
    backgroundColor: "#4e2c39",
    bottom: -90,
    left: 40
  },
  content: {
    padding: 20,
    gap: 16
  },
  headerRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-start",
    gap: 12
  },
  title: {
    color: "#f6fbff",
    fontSize: 28,
    fontWeight: "800",
    letterSpacing: 0.4
  },
  subtitle: {
    color: "#90a9b6",
    marginTop: 4,
    fontSize: 13,
    lineHeight: 18
  },
  guideButton: {
    backgroundColor: "rgba(255,255,255,0.08)",
    borderRadius: 999,
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.08)"
  },
  guideButtonText: {
    color: "#f6fbff",
    fontSize: 13,
    fontWeight: "700"
  },
  sectionCard: {
    backgroundColor: "rgba(255,255,255,0.08)",
    borderRadius: 24,
    padding: 18,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.08)",
    gap: 12
  },
  warningCard: {
    backgroundColor: "rgba(176,110,33,0.2)"
  },
  logCard: {
    backgroundColor: "rgba(0,0,0,0.26)"
  },
  rowSpace: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    gap: 12
  },
  cardTitle: {
    color: "#f8fbff",
    fontSize: 18,
    fontWeight: "800"
  },
  mutedText: {
    color: "#c2d0d8",
    fontSize: 14,
    lineHeight: 21
  },
  pill: {
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6
  },
  runningPill: {
    backgroundColor: "rgba(51, 181, 109, 0.16)"
  },
  idlePill: {
    backgroundColor: "rgba(255, 175, 66, 0.16)"
  },
  pillText: {
    fontSize: 11,
    letterSpacing: 1.1,
    fontWeight: "800",
    color: "#f8fbff"
  },
  toggleRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    gap: 12
  },
  toggleTextWrap: {
    flex: 1,
    gap: 4
  },
  toggleTitle: {
    color: "#f8fbff",
    fontSize: 15,
    fontWeight: "700"
  },
  toggleCaption: {
    color: "#90a9b6",
    fontSize: 12,
    lineHeight: 17
  },
  fieldWrap: {
    gap: 8
  },
  fieldLabel: {
    color: "#b8cad5",
    fontSize: 13,
    fontWeight: "700"
  },
  input: {
    backgroundColor: "rgba(0,0,0,0.22)",
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 12,
    color: "#f6fbff",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.06)"
  },
  editor: {
    minHeight: 160,
    textAlignVertical: "top"
  },
  segmentRow: {
    flexDirection: "row",
    gap: 8,
    marginBottom: 6
  },
  segmentButton: {
    flex: 1,
    borderRadius: 16,
    paddingVertical: 12,
    paddingHorizontal: 10,
    backgroundColor: "rgba(0,0,0,0.22)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.06)"
  },
  segmentButtonActive: {
    backgroundColor: "rgba(30, 194, 181, 0.16)",
    borderColor: "rgba(30, 194, 181, 0.45)"
  },
  segmentButtonText: {
    color: "#c3d1d8",
    textAlign: "center",
    fontSize: 13,
    fontWeight: "700"
  },
  segmentButtonTextActive: {
    color: "#f6fbff"
  },
  stepperCard: {
    backgroundColor: "rgba(0,0,0,0.22)",
    borderRadius: 18,
    padding: 14,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.06)",
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center"
  },
  stepperValue: {
    color: "#f6fbff",
    fontSize: 22,
    fontWeight: "800"
  },
  stepperButtons: {
    flexDirection: "row",
    gap: 10
  },
  miniButton: {
    width: 42,
    height: 42,
    borderRadius: 14,
    backgroundColor: "rgba(255,255,255,0.08)",
    justifyContent: "center",
    alignItems: "center"
  },
  miniButtonText: {
    color: "#f6fbff",
    fontSize: 18,
    fontWeight: "800"
  },
  errorText: {
    color: "#ffbb7d",
    fontSize: 13,
    fontWeight: "700"
  },
  primaryButton: {
    borderRadius: 18,
    paddingVertical: 16,
    paddingHorizontal: 18
  },
  primaryButtonText: {
    color: "#f6fbff",
    fontSize: 16,
    fontWeight: "800",
    textAlign: "center"
  },
  secondaryActions: {
    flexDirection: "row",
    gap: 10
  },
  secondaryButton: {
    flex: 1,
    borderRadius: 18,
    backgroundColor: "rgba(255,255,255,0.10)",
    paddingVertical: 14,
    paddingHorizontal: 14
  },
  secondaryButtonText: {
    color: "#f6fbff",
    textAlign: "center",
    fontSize: 14,
    fontWeight: "700"
  },
  logCount: {
    color: "#90a9b6",
    fontSize: 12,
    fontWeight: "700"
  },
  logBox: {
    backgroundColor: "rgba(0,0,0,0.30)",
    borderRadius: 18,
    padding: 12
  },
  logText: {
    color: "#7df4b9",
    fontSize: 12,
    lineHeight: 18
  },
  modalSafeArea: {
    flex: 1,
    backgroundColor: "#091018"
  },
  modalHeader: {
    paddingHorizontal: 20,
    paddingTop: 12,
    paddingBottom: 4,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center"
  },
  modalTitle: {
    color: "#f8fbff",
    fontSize: 24,
    fontWeight: "800"
  },
  modalContent: {
    padding: 20,
    gap: 16
  }
});
