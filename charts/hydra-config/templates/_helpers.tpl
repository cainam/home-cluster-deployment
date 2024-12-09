{{/*
Common labels
*/}}
{{- define "infopage.labels" -}}
helm.sh/chart: {{ include "infopage.chart" . }}
{{ include "infopage.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "infopage.selectorLabels" -}}
app.kubernetes.io/name: {{ include "infopage.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

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
