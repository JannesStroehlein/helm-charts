{{- define "umami.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "umami.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "umami.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "umami.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

# Bitnami PostgreSQL service DNS (primary)
{{- define "umami.pgHost" -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- end -}}

# Name of the Secret that stores the app DB password (used by both this chart and the subchart)
{{- define "umami.pgAuthSecretName" -}}
{{- default "umami-pg-auth" .Values.postgresql.auth.existingSecret -}}
{{- end -}}

# Construct DATABASE_URL for in-cluster Bitnami PostgreSQL
{{- define "umami.internalDatabaseUrl" -}}
{{- $user := default "umami" .Values.postgresql.auth.username -}}
{{- $db   := default "umami" .Values.postgresql.auth.database -}}
{{- $host := include "umami.pgHost" . -}}
postgresql://{{ $user }}:{{ printf "%s" (include "umami.pgPassword" .) }}@{{ $host }}:5432/{{ $db }}
{{- end -}}

# Fetch/generate a stable strong password for the app DB user.
# - If the secret already exists, reuse its "password" key (prevents changing on upgrade)
# - Otherwise, generate a 48-char random alphanumeric password
{{- define "umami.pgPassword" -}}
{{- $secName := include "umami.pgAuthSecretName" . -}}
{{- $existing := (lookup "v1" "Secret" .Release.Namespace $secName) -}}
{{- if $existing -}}
{{- index $existing.data "password" | b64dec -}}
{{- else -}}
{{- randAlphaNum 48 -}}
{{- end -}}
{{- end -}}
