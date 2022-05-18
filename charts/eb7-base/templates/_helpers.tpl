{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "app.fullname" -}}
{{ include "app.name" . }}
{{- end -}}

{{/*
Hook full name (if any)
*/}}
{{- define "hook.fullname" -}}
hook-{{ include "app.name" . }}
{{- end -}}

{{/*
hook-secret-name (if any)
*/}}
{{- define "hook.secretsProviderName" -}}
{{- if .Values.hookValues.awsSecrets -}}
{{ include "hook.fullname" . }}-{{ .Values.hookValues.awsSecrets | toString | adler32sum | trunc 10 }}
{{- else -}}
{{ include "hook.fullname" . }}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "app.labels" -}}
helm.sh/chart: {{ include "app.chart" . }}
{{ include "app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app_name: {{ include "app.name" . }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end -}}


{{/*
Generate hash-based suffix for secrets provider class
Because for everychange in the content, the name should be changed
*/}}
{{- define "app.secretsProviderName" -}}
{{- if .Values.awsSecrets -}}
{{ include "app.fullname" . }}-{{ .Values.awsSecrets | toString | adler32sum | trunc 10 }}
{{- else -}}
{{ include "app.fullname" . }}
{{- end -}}
{{- end -}}


{{/*
Create affinity rules to run on GPU or CPU nodes
*/}}
{{- define "app.affinityTolerationRules" -}}
{{- if not .Values.runOnLocal -}}
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 10
      podAffinityTerm:
        topologyKey: kubernetes.io/hostname
        labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/instance
            operator: In
            values:
            - "{{ .Release.Name }}"
          - key: app.kubernetes.io/name
            operator: In
            values:
            - "{{ include "app.name" . }}"
{{- if .Values.runOnGPU }}
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: eks.amazonaws.com/nodegroup
          operator: In
          values:
          - gpu-nodes
tolerations:
  - key: nodegroup
    effect: NoSchedule
    value: gpu-nodes
    operator: Equal
{{- else if .Values.runOnDemand }}
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: eks.amazonaws.com/nodegroup
          operator: In
          values:
          - gp-on-demand-nodes
tolerations:
  - key: nodegroup
    effect: NoSchedule
    value: gp-on-demand-nodes
    operator: Equal
{{- else if .Values.runOnBlue }}
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: eks.amazonaws.com/nodegroup
          operator: In
          values:
          - gp-blue-nodes
tolerations:
  - key: nodegroup
    effect: NoSchedule
    value: gp-blue-nodes
    operator: Equal
{{- else if .Values.runOnGreen }}
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: eks.amazonaws.com/nodegroup
          operator: In
          values:
          - gp-green-nodes
tolerations:
  - key: nodegroup
    effect: NoSchedule
    value: gp-green-nodes
    operator: Equal
{{- else }}
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: eks.amazonaws.com/nodegroup
          operator: In
          values:
          - gp-nodes
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "app.SpreadConstraints" -}}
{{- if not .Values.runOnLocal -}}
topologySpreadConstraints: 
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
       matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values:
            - {{ include "app.name" . }}
{{- end -}}
{{- end -}}