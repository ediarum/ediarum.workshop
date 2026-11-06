# The workshop's git host: plain git daemon (git://gitserver/<slug>.git), anonymous read and push.
# Stands in for GitLab, so webdav's pushes stay on the laptop. Only reachable inside the stack.
# `new-repo <slug>` adds an empty repository for an extra project (NEW-PROJECT.md).
FROM alpine:3.20
RUN apk add --no-cache git git-daemon \
    && git config --system --add safe.directory '*'
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY new-repo.sh /usr/local/bin/new-repo
# Windows checkouts may carry CRLF; sh would fail on `set -eu\r`.
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh /usr/local/bin/new-repo \
    && chmod +x /usr/local/bin/new-repo
EXPOSE 9418
HEALTHCHECK --interval=5s --timeout=3s --retries=20 \
  CMD git ls-remote "git://localhost/${PROJECT}.git" HEAD >/dev/null || exit 1
ENTRYPOINT ["/bin/sh", "/usr/local/bin/entrypoint.sh"]
