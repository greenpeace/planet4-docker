#!/usr/bin/env bash

echo "Downloading ngx_pagespeed ${NGX_PAGESPEED_VERSION} from https://github.com/pagespeed/ngx_pagespeed/archive/${NGX_PAGESPEED_VERSION}-${NGX_PAGESPEED_RELEASE}.tar.gz..."

wget --retry-connrefused --waitretry=1 -t 5 -O - https://github.com/pagespeed/ngx_pagespeed/archive/${NGX_PAGESPEED_VERSION}-${NGX_PAGESPEED_RELEASE}.tar.gz --progress=bar --tries=3 | tar zxf - -C /tmp

PSOL_URL=$(cat "/tmp/ngx_pagespeed-${NGX_PAGESPEED_VERSION}-${NGX_PAGESPEED_RELEASE}/PSOL_BINARY_URL")

# The size names must match install/build_psol.sh in mod_pagespeed
if [ "$(uname -m)" = x86_64 ]; then
  PSOL_BIT_SIZE_NAME=x64
else
  PSOL_BIT_SIZE_NAME=ia32
fi

echo "Downloading ngx_pagespeed PSOL ${NGX_PAGESPEED_VERSION} from ${PSOL_URL/\$BIT_SIZE_NAME/$PSOL_BIT_SIZE_NAME}..."

wget --retry-connrefused --waitretry=1 -t 5 -O - ${PSOL_URL/\$BIT_SIZE_NAME/$PSOL_BIT_SIZE_NAME} | tar zxf - -C /tmp/ngx_pagespeed-${NGX_PAGESPEED_VERSION}-${NGX_PAGESPEED_RELEASE}
