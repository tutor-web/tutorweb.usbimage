Internal NUC Intel access point
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The software will configure the internal Wi-fi card as an internal access point, using hostapd. However, only 14 devices can be connected at one time.

POSM found that `this is a hardware issue <https://github.com/posm/posm/issues/84#issuecomment-191415527>`_, and work around it by installing a AP in the SSD M.2 slot.
