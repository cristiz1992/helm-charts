{{- define "allowInsecureSSL" -}}
{{- range .Values.externals -}}
  {{- if and .ingressRoute .ingressRoute.enable .ingressRoute.allowInsecureSSL -}}
    {{- true -}}
  {{- end -}}
{{- end -}}
{{- end -}}