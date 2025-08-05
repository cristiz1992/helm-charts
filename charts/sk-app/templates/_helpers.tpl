{{- define "name" -}}
{{- .Values.nameOverride | default .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "partOf" -}}
{{- .Values.partOf | default (include "name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "version" -}}
{{- .Values.image.tag | default "latest" }}
{{- end }}

{{- define "imagePullSecret" }}
{{- with .Values.image.credentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" $.Values.image.registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}

{{- define "sk.image-name" -}}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository (include "version" .) }}
{{- end -}}

{{- define "sk.pvcName" -}}
{{- .Values.persistence.existingClaim | default .Values.persistence.nameOverride | default (printf "%s-pvc" (include "name" .)) }}
{{- end }}

{{- define "sk.configName" -}}
{{- printf "%s-config" (include "name" .) }}
{{- end }}

{{- define "sk.secretName" -}}
{{- printf "%s-secret" (include "name" .) }}
{{- end }}

{{- define "sk.registrySecretName" -}}
{{- printf "%s-registrysecret" (include "name" .) }}
{{- end }}

{{- define "sk.labels" -}}
app.kubernetes.io/name: {{ include "name" . | quote }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/version: {{ template "version" . }}
app.kubernetes.io/part-of: {{ include "partOf" . | quote }}
{{- end }}

{{- define "sk.selectorLabels" -}}
app.kubernetes.io/name: {{ include "name" . | quote }}
app.kubernetes.io/part-of: {{ include "partOf" . | quote }}
{{- end }}

{{- define "sk.tplvalues.render" -}}
  {{- if typeIs "string" .value }}
      {{- tpl .value .context }}
  {{- else }}
      {{- tpl (.value | toYaml) .context }}
  {{- end }}
{{- end -}}