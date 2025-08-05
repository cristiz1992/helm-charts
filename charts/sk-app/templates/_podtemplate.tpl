{{- define "sk.podTemplate" }}
{{- $root := .root }}
{{- with .context }}
{{- if and .command .args -}}
  {{- fail (printf "Cannot set both command and args.") -}}
{{- end }}
{{- $_ := set . "podExtraAttributes" (deepCopy $root.Values.podExtraAttributes | merge (.podExtraAttributes | default (dict))) }}
{{- $_ := set . "containerExtraAttributes" (deepCopy $root.Values.containerExtraAttributes | merge (.containerExtraAttributes | default (dict))) }}
    metadata:
      annotations:
      {{- if eq .configurationsAndSecretsIncludeMode "Resources" }}
        checksum/config: {{ include (print $root.Template.BasePath "/configmap.yaml") $root | sha256sum }}
        checksum/secret: {{ include (print $root.Template.BasePath "/secret.yaml") $root | sha256sum }}
      {{- end }}
      labels:
      {{- include "sk.labels" $root | nindent 8 }}
        app.kubernetes.io/component: {{ .component | quote }}
    spec:
      {{- if $root.Values.image.credentials.username }}
      imagePullSecrets:
        - name: {{ include "sk.registrySecretName" $root | quote }}
      {{- end }}
      {{- with .initContainers }}
      initContainers:
      {{- toYaml . | nindent 6 }}
      {{- end }}
      containers:
      - image: {{ include "sk.image-name" $root | quote }}
        imagePullPolicy: {{ $root.Values.image.pullPolicy | quote }}
        name: {{ include "name" $root | quote }}
        {{- with .command }}
        command: 
        {{- toYaml . | nindent 10 }}
        {{- end }}
        {{- with .args }}
        args: 
        {{- toYaml . | nindent 10 }}
        {{- end }}
        resources:
          {{- with $root.Values.resources }}
          {{- toYaml . | nindent 10 }}
          {{- end }}
        {{- $healthchecksPort := (default ($root.Values.ports.skApp).containerPort .healthchecksPort) }}
        {{- $healthchecksScheme := (default "HTTP" .healthchecksScheme) }}
        {{- if .readinessPath }}
        readinessProbe:
          httpGet:
            path: {{ .readinessPath | quote }}
            port: {{ $healthchecksPort }}
            scheme: {{ $healthchecksScheme }}
          {{- toYaml $root.Values.readinessProbe | nindent 10 }}
        {{- end }}
        {{- if .readinessPath }}
        livenessProbe:
          httpGet:
            path: {{ .livenessPath | quote }}
            port: {{ $healthchecksPort }}
            scheme: {{ $healthchecksScheme }}
          {{- toYaml $root.Values.livenessProbe | nindent 10 }}
        {{- end }}
        ports:
        {{- range $name, $config := $root.Values.ports }}
        {{- if $config }}
          - name: {{ $name | lower | quote }}
            containerPort: {{ $config.containerPort }}          
            protocol: {{ default "TCP" $config.protocol | quote }}
        {{- end }}
        {{- end }}
        volumeMounts:        
          {{- if and $root.Values.persistence.enable (not .excludeVolumes) }}
          - name: {{ include "sk.pvcName" $root | quote }}
            mountPath: {{ $root.Values.persistence.path | quote }}
            {{- if $root.Values.persistence.subPath }}
            subPath: {{ $root.Values.persistence.subPath | quote }}
            {{- end }}
          {{- end }}
          - name: "tmp"
            mountPath: "/tmp"
          {{- if and $root.Values.additionalVolumeMounts (not .excludeVolumes) }}
            {{- include "sk.tplvalues.render" (dict "value" $root.Values.additionalVolumeMounts "context" $root) | nindent 10 }}
          {{- end }}
        env:          
        {{- with $root.Values.env }}
          {{- toYaml . | nindent 10 }}
        {{- end }}
        {{- if eq .configurationsAndSecretsIncludeMode "Environment" }}
          {{- range $key, $val := $root.Values.configurations }}
          - name: {{ $key }}
            value: {{ $val | quote }}
          {{- end }}
          {{- range $key, $val := $root.Values.secrets }}
          - name: {{ $key }}
            value: {{ $val | quote }}
          {{- end }}
        {{- end }}
        envFrom:
          {{- with $root.Values.envFrom }}
            {{- toYaml . | nindent 10 }}
          {{- end }}
          {{- $name := (include "name" $root ) -}}
          {{- if eq .configurationsAndSecretsIncludeMode "Resources" }}
            {{- with $root.Values.configurations }}
          - configMapRef:
              name: {{ include "sk.configName" $root | quote }}
            {{- end }}
            {{- with $root.Values.secrets }}
          - secretRef:
              name: {{ include "sk.secretName" $root | quote }}
            {{- end }}
          {{- end }}
          {{- with .containerExtraAttributes }}
            {{- toYaml . | nindent 10 }}
          {{- end }}
      {{- if .additionalContainers }}
        {{- toYaml .additionalContainers | nindent 6 }}
      {{- end }}
      volumes:
        {{- if and $root.Values.persistence.enable (not .excludeVolumes) }}
        - name: {{ include "sk.pvcName" $root | quote }}
          persistentVolumeClaim:
            claimName: {{ include "sk.pvcName" $root | quote }}
        {{- end }}
        - name: "tmp"
          emptyDir: {}
        {{- if and $root.Values.additionalVolumes (not .excludeVolumes) }}
          {{- include "sk.tplvalues.render" (dict "value" $root.Values.additionalVolumes "context" $root) | nindent 8 }}
        {{- end }}
      terminationGracePeriodSeconds: 30
      {{- with .podExtraAttributes }}
        {{- toYaml . | nindent 6 }}
      {{- end }}
{{ end -}}
{{ end -}}