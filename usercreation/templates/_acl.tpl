{{- define "kafka-users.acls" -}}
{{- $profile := .aclProfile -}}

{{- if eq $profile "admin" }}
- resource:
    type: topic
    name: "*"
    patternType: literal
  operation: All
- resource:
    type: group
    name: "*"
    patternType: literal
  operation: All
- resource:
    type: cluster
    name: {{ .clusterName }}
  operation: All

{{- else if eq $profile "producer" }}
- resource:
    type: topic
    name: {{ .topic }}
    patternType: literal
  operation: Write
- resource:
    type: topic
    name: {{ .topic }}
    patternType: literal
  operation: Describe

{{- else if eq $profile "consumer" }}
- resource:
    type: topic
    name: {{ .topic }}
    patternType: literal
  operation: Read
- resource:
    type: group
    name: {{ .group }}
    patternType: literal
  operation: Read

{{- else if eq $profile "custom" }}
{{- toYaml .acls | nindent 0 }}

{{- end }}
{{- end }}
