{{/*
Create the name of the service account to use
*/}}
{{- define "operator.serviceAccountName" -}}
{{- if .Values.operator.serviceAccount.create }}
{{- default "default" .Values.operator.name }}
{{- else }}
{{- default "default" .Values.operator.name }}
{{- end }}
{{- end }}
